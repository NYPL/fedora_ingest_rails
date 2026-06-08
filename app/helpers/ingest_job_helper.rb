# frozen_string_literal: true
require 'nokogiri'

module IngestJobHelper
  RELEASE_MASTER_OK = 'Release Source File for Free (i.e., high-res or master can be released to the public)'
  PUBLIC_DOMAIN_RIGHTS_CODES = %w(
    PDCDPP PDNCN PDREN PDEXP PDADD PDUSG PPD PPD100 CC_0
  )

  def ingest!(ingest_request, test_mode = false)

    mms_client = MmsClient.new(mms_url: Rails.application.config.mms_url,
                               user_name: Rails.application.config.mms_http_basic_username,
                               password: Rails.application.config.mms_http_basic_password)

    # Fetch stuff from MMS
    mods                        = mms_client.mods_for(ingest_request.uuid)
    type_of_resource            = Nokogiri::XML(mods).css('typeOfResource:first').text
    parent_and_item_repo_docs   = mms_client.repo_docs_for(ingest_request.uuid)
    captures                    = mms_client.captures_for_item(ingest_request.uuid)

    item_has_allMaps_data = captures.any? { |c| MapwarperDataset.has_uuid?(c[:uuid]) }

    parent_uuids = []
    local_parent_and_item_repo_solr_docs_to_update = []

    index_time_plain = Time.current
    index_time_s = RepoSolrDoc.format_as_solr_s(index_time_plain)
    index_time_dt = RepoSolrDoc.format_as_solr_dt(index_time_plain)

    parent_and_item_repo_docs.each do |doc|
      doc_uuid = doc['uuid']
      parent_uuids << doc_uuid
      local_parent_or_item_repo_solr_doc = RepoSolrDoc.find_or_create_by!(uuid: doc_uuid)

      doc['dateIndexed_s'] = index_time_s
      doc['dateIndexed_dt'] = index_time_dt

      if doc_uuid == ingest_request.uuid # this check prevents the has_allMaps_data field from getting set on parent docs
        doc['has_allMaps_data'] = item_has_allMaps_data
      end

      if local_parent_or_item_repo_solr_doc.first_indexed.nil?
        doc['firstIndexed_s'] = index_time_s
        doc['firstIndexed_dt'] = index_time_dt
        local_parent_and_item_repo_solr_docs_to_update << local_parent_or_item_repo_solr_doc
      else
        first_indexed_plain = local_parent_or_item_repo_solr_doc.first_indexed.to_time
        first_indexed = first_indexed_plain.iso8601(3)
        doc['firstIndexed_s'] = first_indexed
        doc['firstIndexed_dt'] = RepoSolrDoc.format_as_solr_dt(first_indexed_plain)
      end
    end

    ocr_collection_uuids = [
      "da4687f0-cc71-0130-fb40-58d385a7b928",  # Oral History Collection
      "9ea5d5b0-1117-0132-7932-58d385a7b928",  # Green Books Collection
    ]
    is_ocr_collection = (parent_uuids & ocr_collection_uuids).any?

    # add docs to solr, setting the flag to check the old parents for existence.
    repo_solr = RepoSolrClient.new
    repo_solr.add_docs_to_solr(parent_and_item_repo_docs, true)

    local_repo_capture_solr_docs_to_update = []

    seen_capture_uuids = []

    captures.each do |capture|
      seen_capture_uuids << capture[:uuid]
      uuid = capture[:uuid]
      image_id = capture[:image_id]
      pid = "uuid:#{uuid}"

      rights = mms_client.rights_for(uuid)
      uses = Nokogiri::XML(rights).xpath('./nyplRights/useStatement/use').map{|u| u.text}
      release_master = uses.any?{ |use|
        (use == RELEASE_MASTER_OK) \
        || (PUBLIC_DOMAIN_RIGHTS_CODES.include?(use))
      }

      # Datastreams with info from the filestore database of image derivatives
      image_filestore_entries = ImageFilestoreEntry.where(file_id: capture[:image_id], status: 4)
      highres_permalink = nil
      image_filestore_entries.each do |f|
        file_uuid   = f.uuid
        file_label  = f.get_type(f.type)
        file_name   = f.file_name
        extension   = file_name.split('.')[-1]
        mime_type   = f.get_mimetype(extension)
      end

      # Datastreams with info from the `Capture` Level
      rels_ext = mms_client.rels_ext_for(uuid)

      # Repo API solr for capture.
      capture_solr_doc = mms_client.repo_doc_for(uuid)
      capture_solr_doc['has_allMaps_data'] = MapwarperDataset.has_uuid?(uuid)

      if highres_permalink.present? && release_master
        capture_solr_doc['highResLink'] = highres_permalink
      else
        capture_solr_doc['highResLink'] = nil # unpublishes the link if it exists.
      end

      if is_ocr_collection
        ocr_content = S3Client.new.ocr_for(uuid)

        # Get the plain text from the ocr content
        if not ocr_content.nil?
          if ocr_content.include?("<alto>")
            capture_solr_doc['ocr_text'] = "#{ENV['OCR_SOLR_FILE_PATH']}/ocr/#{uuid}"
            capture_solr_doc['mets_alto'] = ocr_content
            capture_solr_doc['hasOCR'] = true
            capture_solr_doc['captureText_ocrtext'] = Nokogiri::XML(ocr_content).xpath('//String').collect { |s| s.at('@CONTENT').text }.join(" ")

          elsif ocr_content.include?("</html>")
            capture_solr_doc['hocr'] = ocr_content
            capture_solr_doc['hasOCR'] = capture_solr_doc['hocr'].present?
            capture_solr_doc['captureText_ocrtext'] = Nokogiri::HTML(ocr_content).xpath('//*[local-name()="span" and @class="ocrx_word"]').collect { |s| s.text }.join(" ").squish
          end
        end
      end

      local_repo_capture_solr_doc = RepoSolrDoc.find_or_create_by!(uuid: uuid)
      capture_solr_doc['dateIndexed_s'] = index_time_s
      capture_solr_doc['dateIndexed_dt'] = index_time_dt
      first_indexed_plain = local_repo_capture_solr_doc&.first_indexed&.to_time || index_time_plain
      first_indexed = first_indexed_plain.iso8601(3)
      capture_solr_doc['firstIndexed_s'] = first_indexed
      capture_solr_doc['firstIndexed_dt'] = RepoSolrDoc.format_as_solr_dt(first_indexed_plain)

      local_repo_capture_solr_docs_to_update << local_repo_capture_solr_doc if local_repo_capture_solr_doc.first_indexed.nil?

      # add docs to solr without checking parents this time
      repo_solr.add_docs_to_solr(capture_solr_doc)
      
      # ensure the suppressed value is set to false in the database
      # imageID comes direct from mms before it's copied into the imageID_string file on index
      ImageFilestoreEntry.unsuppress_all_for_file_id(capture_solr_doc['imageID']) if capture_solr_doc['imageID'].present?

      Delayed::Worker.logger.info("ingested capture #{uuid}", uuid: ingest_request.uuid)
    end

    # commit changes
    repo_solr.commit_index_changes

    # sometimes captures are deleted or suppressed, and we need to pull them back
    repo_solr.delete_unseen_captures_below(ingest_request.uuid, seen_capture_uuids, mms_client)

    # do not update first indexed until we successfully return from commit
    # this should only update first indexed where it is not yet set
    local_repo_capture_solr_docs_to_update.each { |d| d.update(first_indexed: index_time_s) }
    local_parent_and_item_repo_solr_docs_to_update.each { |d| d.update(first_indexed: index_time_s) }

    # update parents based on new info, from the bottom to the top.
    repo_solr.update_key_fields_for_parent_uuids(parent_uuids.reverse)

    Delayed::Worker.logger.info('Done ingesting all captures of Item', uuid: ingest_request.uuid)
  end
  
  def fetch_url(url)
    uri = URI(url)
    res = Net::HTTP.delay.get_response(uri) # no need to catch exceptions here, because I want to see errors. 
  end
end
