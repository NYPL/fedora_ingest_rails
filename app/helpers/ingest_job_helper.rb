# frozen_string_literal: true
require 'nokogiri'

module IngestJobHelper
  RELEASE_MASTER_OK = 'Release Source File for Free (i.e., high-res or master can be released to the public)'
  PUBLIC_DOMAIN_RIGHTS_CODES = %w(
    PDCDPP PDNCN PDREN PDEXP PDADD PDUSG PPD PPD100 CC_0
  )

  def ingest!(ingest_request, test_mode = false)

    # Fedora is not available in QA
    fedora_client = FedoraClient.new unless test_mode

    mms_client = MMSClient.new(mms_url: Rails.application.secrets.mms_url,
                               user_name: Rails.application.secrets.mms_http_basic_username,
                               password: Rails.application.secrets.mms_http_basic_password)

    # Fetch stuff from MMS
    mods                        = mms_client.mods_for(ingest_request.uuid)
    dublin_core                 = mms_client.dublin_core_for(ingest_request.uuid)
    type_of_resource            = Nokogiri::XML(mods).css('typeOfResource:first').text
    parent_and_item_repo_docs   = mms_client.repo_docs_for(ingest_request.uuid)

    parent_uuids = []
    local_parent_and_item_repo_solr_docs_to_update = []
    index_time = Time.now.iso8601(3)

    parent_and_item_repo_docs.each do |doc|
      doc_uuid = doc['uuid']
      parent_uuids << doc_uuid
      local_parent_or_item_repo_solr_doc = RepoSolrDoc.find_or_create_by!(uuid: doc_uuid)

      doc['dateIndexed_s'] = index_time

      if local_parent_or_item_repo_solr_doc.first_indexed.nil?
        doc['firstIndexed_s'] = index_time
        local_parent_and_item_repo_solr_docs_to_update << local_parent_or_item_repo_solr_doc
      else
        doc['firstIndexed_s'] = local_parent_or_item_repo_solr_doc.first_indexed.to_time.iso8601(3)
      end
    end

    # magic uuid for our one and only oral history collection. TODO:     Make this more universal. KAK - Sept 20 2021
    in_oral_history_collection = parent_uuids.include?('da4687f0-cc71-0130-fb40-58d385a7b928')

    repo_solr = RepoSolrClient.new
    repo_solr.add_docs_to_solr(parent_and_item_repo_docs)

    local_repo_capture_solr_docs_to_update = []

    mms_client.captures_for_item(ingest_request.uuid).each do |capture|
      uuid = capture[:uuid]
      image_id = capture[:image_id]
      pid = "uuid:#{uuid}"

      #rights_response = mms_client.rights_for(uuid)
      rights = mms_client.rights_for(uuid)
      uses = Nokogiri::XML(rights).xpath('./nyplRights/useStatement/use').map{|u| u.text}
      release_master = uses.any?{ |use|
        (use == RELEASE_MASTER_OK) \
        || (PUBLIC_DOMAIN_RIGHTS_CODES.include?(use))
      }

      # Fedora is not available in QA
      unless test_mode
        digital_object = fedora_client.repository.find_or_initialize(pid)
        digital_object.label = extract_title_from_dublin_core(dublin_core)[0..249]
        digital_object.save
        ##  For some reason this can only be done on saved objects
        digital_object.models << 'info:fedora/nypl-model:image' # KK TODO: Ask JV why we do this and if it should apply to AMI.

        # Datastreams with info from the `Item` Level
        if mods.present?
          fedora_client.repository.add_datastream(pid: pid, dsid: 'MODSXML', content: mods, mimeType: 'text/xml', checksumType: 'MD5', dsLabel: 'MODS XML record for this object')
        end

        if dublin_core.present?
          fedora_client.repository.add_datastream(pid: pid, dsid: 'DC',      content: dublin_core, formatURI: 'http://www.openarchives.org/OAI/2.0/oai_dc/', mimeType: 'text/xml', checksumType: 'MD5', dsLabel: 'DC XML record for this object')
        end

        # Datastreams with info from the `Capture` level
        if rights.present?
          fedora_client.repository.add_datastream(pid: pid, dsid: 'RIGHTS',  content: rights, mimeType: 'text/xml', checksumType: 'MD5', dsLabel: 'Rights XML record for this object')
        end
      end

      # Datastreams with info from the filestore database of image derivatives
      image_filestore_entries = ImageFilestoreEntry.where(file_id: capture[:image_id], status: 4)
      highres_permalink = nil
      image_filestore_entries.each do |f|
        file_uuid   = f.uuid
        file_label  = f.get_type(f.type)
        file_name   = f.file_name
        extension   = file_name.split('.')[-1]
        mime_type   = f.get_mimetype(extension)
        if file_label == 'MASTER_IMAGE' && release_master
          full_res_path = "#{FEDORA_LINK_URL}/objects/#{pid}/datastreams/MASTER_IMAGE/content"
          highres_permalink = PermalinkClient.new(uuid: file_uuid).fetch_or_mint_permalink(full_res_path)
        end

        unless test_mode
          if file_label != 'Unknown'
            datastream_options = { pid: pid, dsid: file_label, content: nil, controlGroup: 'E', mimeType: mime_type, checksumType: 'DISABLED', dsLocation: "http://local.fedora.server/resolver/#{file_uuid}", dsLabel: file_label + ' for this object', altIds: [highres_permalink] }
            fedora_client.repository.add_datastream(datastream_options)
          end
        end
      end

      # Datastreams with info from the `Capture` Level
      rels_ext = mms_client.rels_ext_for(uuid)

      # Repo API solr for capture.
      capture_solr_doc = mms_client.repo_doc_for(uuid)

      if highres_permalink.present? && release_master
        capture_solr_doc['highResLink'] = highres_permalink
      else
        capture_solr_doc['highResLink'] = nil # unpublishes the link if it exists.
      end

      if in_oral_history_collection
        mets_alto = S3Client.new.mets_alto_for(uuid)
        capture_solr_doc['mets_alto'] = mets_alto
        capture_solr_doc['hasOCR'] = capture_solr_doc['mets_alto'].present?

        # Get the plain text from the alto.
        ndoc = Nokogiri::XML(mets_alto)
        plain_text = ndoc.xpath('//String').collect { |s| s.at('@CONTENT').text }.join(" ")
        capture_solr_doc['captureText_ocrtext'] = plain_text
      end

      local_repo_capture_solr_doc = RepoSolrDoc.find_or_create_by!(uuid: uuid)
      capture_solr_doc['dateIndexed_s'] = index_time
      capture_solr_doc['firstIndexed_s'] = local_repo_capture_solr_doc&.first_indexed&.to_time&.iso8601(3) || index_time
      local_repo_capture_solr_docs_to_update << local_repo_capture_solr_doc if local_repo_capture_solr_doc.first_indexed.nil?

      repo_solr.add_docs_to_solr(capture_solr_doc)

      # Fedora is not available in qa
      unless test_mode || rels_ext.blank?
        # Post the datastream to the repository
        fedora_client.repository.add_datastream(
          pid: pid,
          dsid: 'RELS-EXT',
          content: rels_ext,
          mimeType: 'application/rdf+xml',
          checksumType: 'MD5',
          dsLabel: 'RELS-EXT XML record for this object'
        )
      end

      digital_object.save unless test_mode

      Delayed::Worker.logger.info("ingested capture #{uuid}", uuid: ingest_request.uuid)
    end

    repo_solr.commit_index_changes

    # do not update first indexed until we successfully return from commit
    local_repo_capture_solr_docs_to_update.each { |d| d.update_attributes(first_indexed: index_time) }
    local_parent_and_item_repo_solr_docs_to_update.each { |d| d.update_attributes(first_indexed: index_time) }

    Delayed::Worker.logger.info('Done ingesting all captures of Item', uuid: ingest_request.uuid)
  end

  def extract_title_from_dublin_core(dublin_core)
    Nokogiri::XML(dublin_core).remove_namespaces!.css('title').text.strip.truncate(250, separator: ' ...')
  end
end
