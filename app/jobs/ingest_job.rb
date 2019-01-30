require 'nokogiri'
Rubydora.logger = NyplLogFormatter.new(STDOUT)

IngestJob = Struct.new(:ingest_request_id) do
  def perform
    @ingest_request = IngestRequest.where(id: ingest_request_id).first
    if @ingest_request
      ingest!
      @ingest_request.update_attributes(ingested_at: Time.now.utc)
    end
  end

  def ingest!
    fedora_client = FedoraClient.new
    mms_client = MMSClient.new(mms_url: Rails.application.secrets.mms_url,
                               user_name: Rails.application.secrets.mms_http_basic_username,
                               password: Rails.application.secrets.mms_http_basic_password)
    rels_ext_index_client = RelsExtIndexClient.new(
                              rels_ext_solr_url: Rails.application.secrets.rels_ext_solr_url)

    # Fetch stuff from MMS
    mods              = mms_client.mods_for(@ingest_request.uuid)
    dublin_core       = mms_client.dublin_core_for(@ingest_request.uuid)
    type_of_resource  = Nokogiri::XML(mods).css('typeOfResource:first').text
    
    # Create an array of uuids to batch send to tilecutter
    uuids_for_tilecutting = []

    mms_client.captures_for_item(@ingest_request.uuid).each do |capture|
      uuid = capture[:uuid]
      image_id = capture[:image_id]
      
      # Pull rights for each capture. Needed because now we manage captures on an atomic level. 
      rights = mms_client.rights_for(uuid)
      uuids_for_tilecutting << uuid if approved_for_tilecutting?(rights_export, uuid)

      pid = "uuid:#{uuid}"

      # Figure out if it is ok to release high res file. Handled by string in rights statement right now.
      # necessary for determining if we need to get master image permalinks.
      high_res_ok = "Release Source File for Free (i.e., high-res or master can be released to the public)"
      release_master = rights.to_s.scan(high_res_ok).present? if rights

      digital_object = fedora_client.repository.find_or_initialize(pid)
      digital_object.label = extract_title_from_dublin_core(dublin_core)
      digital_object.save
      ##  For some reason this can only be done on saved objects
      digital_object.models << 'info:fedora/nypl-model:image' # KK TODO: Ask JV why we do this and if it should apply to AMI.

      # Datastreams with info from the `Item` Level
      fedora_client.repository.add_datastream(pid: pid, dsid: 'MODSXML', content: mods, mimeType: 'text/xml', checksumType: 'MD5', dsLabel: 'MODS XML record for this object')
      fedora_client.repository.add_datastream(pid: pid, dsid: 'DC',      content: dublin_core, formatURI: 'http://www.openarchives.org/OAI/2.0/oai_dc/', mimeType: 'text/xml', checksumType: 'MD5', dsLabel: 'DC XML record for this object')
      
      # Datastreams with info from the `Capture` level 
      fedora_client.repository.add_datastream(pid: pid, dsid: 'RIGHTS',  content: rights, mimeType: 'text/xml', checksumType: 'MD5', dsLabel: 'Rights XML record for this object')

      # Datastreams with info from the filestore database of image derivatives
      image_filestore_entries = ImageFilestoreEntry.where(file_id: capture[:image_id], status: 4)
      image_filestore_entries.each do |f|
        file_uuid   = f.uuid
        file_label  = f.get_type(f.type)
        file_name   = f.file_name
        extension   = file_name.split('.')[-1]
        mime_type   = f.get_mimetype(extension)
        permalinks  = []
        if file_label == "MASTER_IMAGE" && release_master
          permalink = PermalinkClient.new(uuid: file_uuid).fetch_or_mint_permalink("#{ENV['FEDORA_URL']}/objects/#{pid}/datastreams/MASTER_IMAGE/content")
          permalinks << permalink if permalink.present?
        end
        if file_label != 'Unknown'
          datastream_options = {pid: pid, dsid: file_label, content: nil, controlGroup: 'E', mimeType: mime_type, checksumType: 'DISABLED', dsLocation: "http://local.fedora.server/resolver/#{file_uuid}" , dsLabel: file_label + ' for this object', altIds: permalinks}
          fedora_client.repository.add_datastream(datastream_options)
        end
      end

      rels_ext = mms_client.rels_ext_for(uuid)
      rels_for_indexing = mms_client.full_rels_ext_solr_docs_for(uuid)
      rels_indexer_response = rels_ext_index_client.post_solr_doc(uuid, rels_for_indexing)

      # Datastreams with info from the `Capture` Level
      fedora_client.repository.add_datastream(pid: pid, dsid: 'RELS-EXT', content: rels_ext, mimeType: 'application/rdf+xml', checksumType: 'MD5', dsLabel: 'RELS-EXT XML record for this object')
      digital_object.save
      Delayed::Worker.logger.info("ingested capture #{uuid}", uuid: @ingest_request.uuid)
    end
    
    begin
      request_tilecutting_for(uuids_for_tilecutting) if uuids_for_tilecutting.present?
      Delayed::Worker.logger.info("Sent uuids for tilecutting. #{uuids}", uuids: uuids_for_tilecutting)
    rescue Exception => e
      Delayed::Worker.logger.error("Failed to send tilecutting request for #{uuids}, exception: #{e}", uuids: uuids_for_tilecutting)
    end

    Delayed::Worker.logger.info('Done ingesting all captures of Item', uuid: @ingest_request.uuid)
  end

  private

  def extract_title_from_dublin_core(dublin_core)
    Nokogiri::XML(dublin_core).remove_namespaces!.css('title').text.strip.truncate(250, separator: " ...")
  end
  
  # read the xml given as the rights export; if it matches the public domain profile, return true
  def permits_tilecutting?(rights_export, uuid)
    public_domain_codes = ['PPD100','PPD','PDUSG','PDREN','PDNCN','PDCDPP','PDADD','ICNYPL']
    copyright_status = Nokogiri::XML(rights_export).remove_namespaces!.xpath('//use[@type="copyright_status"]').text.strip
    public_domain_codes.include?(copyright_status)
  end
  
  # Send an array of uuids to the tilecutting service
  # The uuids here can be representative of captures, items, containers, or collections. ('inputCaptures' can be misleading, don't let it fool you.)
  # The service provides no useful feedback at present, so the best we can do is send them.
  def request_tilecutting_for(uuids)
    require 'net/http'
    require 'uri'
    require 'json'

    uri = URI.parse(IMAGE_TILECUTTING_SERVICE_URL)
    request = Net::HTTP::Post.new(uri)
    request.content_type = "application/json"
    request["Accept"] = "application/json"
    request.body = JSON.dump({
      "inputCaptures" => uuids
    })

    req_options = {
      use_ssl: uri.scheme == "https",
    }

    response = Net::HTTP.start(uri.hostname, uri.port, req_options) do |http|
      http.request(request)
    end
  end
end
