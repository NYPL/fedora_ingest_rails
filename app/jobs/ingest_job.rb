require 'nokogiri'

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

    # Fetch stuff from MMS
    mods              = mms_client.mods_for(@ingest_request.uuid)
    rights            = mms_client.rights_for(@ingest_request.uuid)
    dublin_core       = mms_client.dublin_core_for(@ingest_request.uuid)
    type_of_resource  = Nokogiri::XML(mods).css('typeOfResource:first').text

    mms_client.captures_for_item(@ingest_request.uuid).each do |capture|
      uuid = capture[:uuid]
      image_id = capture[:image_id]

      pid = "uuid:#{uuid}"
      digital_object = fedora_client.repository.find_or_initialize(pid)
      digital_object.label = extract_title_from_dublin_core(dublin_core)
      digital_object.save
      ##  For some reason this can only be done on saved objects
      digital_object.models << 'info:fedora/nypl-model:image' # KK TODO: Ask JV why we do this and if it should apply to AMI.

      # Datastreams with info from the `Item` Level
      fedora_client.repository.add_datastream(pid: pid, dsid: 'MODSXML', content: mods, mimeType: 'text/xml', checksumType: 'MD5', dsLabel: 'MODS XML record for this object')
      fedora_client.repository.add_datastream(pid: pid, dsid: 'RIGHTS',  content: rights, mimeType: 'text/xml', checksumType: 'MD5', dsLabel: 'Rights XML record for this object')
      fedora_client.repository.add_datastream(pid: pid, dsid: 'DC',      content: dublin_core, formatURI: 'http://www.openarchives.org/OAI/2.0/oai_dc/', mimeType: 'text/xml', checksumType: 'MD5', dsLabel: 'DC XML record for this object')

      # Datastreams with info from the filestore database of image derivatives
      image_filestore_entries = ImageFilestoreEntry.where(file_id: capture[:image_id])
      image_filestore_entries.each do |f|
        file_uuid   = f.uuid
        file_label  = f.get_type(f.type)
        checksum    = f.checksum
        file_name   = f.file_name
        extension   = file_name.split('.')[-1]
        mime_type   = f.get_mimetype(extension)
        permalinks  = []
        # KK TODO: add permalink to master image to permalinks / altIds
        # Legacy related java code
        # if(label.equals("MASTER_IMAGE") && releaseMaster){
        #   String permalink = getPermalink("http://repo.nypl.org/fedora/objects/uuid:"+id[1]+"/datastreams/MASTER_IMAGE/content");
        #   permalinks.add(permalink);
        # }
        if file_label != 'Unknown'
          datastream_options = {pid: pid, dsid: file_label, content: nil, controlGroup: 'E', mimeType: mime_type, checksumType: 'MD5', dsLocation: 'http://local.fedora.server/resolver/' + file_uuid, dsLabel: file_label + ' for this object', altIds: permalinks}
          datastream_options.merge!({checksum: checksum}) if Rails.env.production?
          fedora_client.repository.add_datastream(datastream_options)
        end
      end

      rels_ext = mms_client.rels_ext_for(uuid)

      # Datastreams with info from the `Capture` Level
      fedora_client.repository.add_datastream(pid: pid, dsid: 'RELS-EXT', content: rels_ext, mimeType: 'application/rdf+xml', checksumType: 'MD5', dsLabel: 'RELS-EXT XML record for this object')
      digital_object.save
      Delayed::Worker.logger.debug("ingested capture #{uuid}", uuid: @ingest_request.uuid)
    end

    Delayed::Worker.logger.debug('Done ingesting all captures of Item', uuid: @ingest_request.uuid)
  end

  private
  
  def find_or_create_permalink(link)
    # KK TODO: Hook this up for real to production resources
  end

  def extract_title_from_dublin_core(dublin_core)
    Nokogiri::XML(dublin_core).remove_namespaces!.css('title').text.strip
  end

end
