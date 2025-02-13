# frozen_string_literal: true

require 'uri'
require 'http'
require 'rsolr'

class RepoSolrClient

  NYPL_LOCATIONS = [
    'All NYPL',
    'All research library locations',
    'LPA-wide',
    'LPA Research Reading Room',
    'Schomburg-wide',
    'SCH: Print/Photographs/Manuscripts',
    'SCH: Archives/Rare Books',
    'SCH: Moving Image and Recorded Sound',
    'SASB-wide',
    'SASB 111: Jewish',
    'SASB 117: Maps',
    'SASB 119: Local History',
    'SASB 300: Art and Architecture',
    'SASB 308: Prints/Photographs/Spencer',
    'SASB 319: Shelly',
    'SASB 320: Berg',
    'SASB 328: Manuscripts/Rare Books/Arents',
    'SIBL-wide'
  ].freeze  

  def initialize(_options = {})
    # We don't need to instantiate a repo solr client ... until we do. We mock it in some of our tests.
    if Rails.env != 'test' || ( Rails.env == 'test' && Rails.application.config.repo_solr_url == 'http://fake.com/solr' )
      @rsolr = RSolr.connect url: Rails.application.config.repo_solr_url
      @rsolr_params = { wt: :ruby, q: '*:*' }
    end
  end

  def add_docs_to_solr(solr_docs_array, check_parents=false)
    if @rsolr
      update_key_fields(solr_docs_array)

      if check_parents == true

        # grab the item document, it will always be first.
        new_item_document = solr_docs_array.first

        # commit the parents now, they will be any documents not in first position.
        @rsolr.add solr_docs_array[1..-1]
        @rsolr.commit

        # now process the item with the special method.
        update_index_and_delete_empty_parents(new_item_document)
      else
        @rsolr.add solr_docs_array
      end
    end
  end

  def get_doc(uuid)
    if @rsolr
      rsolr_params = { q: "uuid:#{uuid}" }
      resp = @rsolr.get 'select', params: rsolr_params
      resp['response']
    end
  end
  
  def get_number_of_children_for_parent_uuid(uuid)
    if @rsolr
      # Find out how many actual items are beneath this parent.
      rsolr_params = { q: "parentUUID:\"#{uuid}\" AND type_s:Item", rows: 0 }
      resp = @rsolr.get 'select', params: rsolr_params
      resp['response']['numFound']
    end
  end

  def remove_doc_for(uuid)
    @rsolr.delete_by_query "uuid:#{uuid}" if @rsolr
  end

  def commit_index_changes
    @rsolr.commit if @rsolr
  end

  def get_solr_doc_for(uuid)
    mms_client = MmsClient.new(mms_url: Rails.application.config.mms_url)
    mms_client.repoapi_solr_doc_for(uuid)
  end

  def update_key_fields(solr_docs_array)
    return unless @rsolr && solr_docs_array.present?
  
    nypl_locations_query = NYPL_LOCATIONS.map { |loc| "\"#{loc}\"" }.join(" OR ")

    uuids = solr_docs_array.map { |doc| doc["uuid"] }
  
    # Prepare updates in bulk
    updates = solr_docs_array.map do |solr_doc|
      uuid = solr_doc["uuid"]
      type = solr_doc["type_s"]&.gsub("http://uri.nypl.org/vocabulary/repository_terms#", "")
  
      # Skip Captures always as the fields we're adding don't pertain to them. 
      next if type == "Capture" || type.blank?
  
      # Add timestamps for this update
      update_hash = {
        "uuid" => uuid,
        "dateIndexed_s" => { set: RepoSolrDoc.get_datetime_s },
        "dateIndexed_dt" => { set: RepoSolrDoc.get_datetime_dt }
      }
      
      representative_children = get_representative_children_for(uuid, type)
      representative_docs = [representative_children, solr_doc].flatten

      # Set containsMultipleCaptures
      if type == "Item"
        update_hash["containsMultipleCaptures"] = representative_children.count > 1
      else
        # there is a small chance items can change type, so let's just make sure to set this to nil if not an item
        update_hash["containsMultipleCaptures"] = nil
      end
  
      # Set itemsCount via numItems_s (it's a copyfield)
      update_hash["numItems_s"] = type == "Item" ? 1 : get_number_of_children_for_parent_uuid(uuid)
  
      # Set containsAVMaterial
      av_material = representative_docs.any? do |doc|
        doc["typeOfResource_mtxt_s"]&.include?("sound recording") || doc["typeOfResource_mtxt_s"]&.include?("moving image")
      end
      update_hash["containsAVMaterial"] = av_material
  
      # Set containsOnsiteMaterial
      onsite_material = representative_docs.any? do |doc|
        nypl_conditions = doc["useRestriction_rtxt_s"]&.any? { |r| NYPL_LOCATIONS.include?(r) }
        onsite_conditions = doc["use_rtxt_s"]&.include?("Can be displayed on NYPL premises") &&
                            !doc["use_rtxt_s"]&.include?("Can be used on NYPL website")
        nypl_conditions || onsite_conditions
      end
      update_hash["containsOnSiteMaterial"] = onsite_material
  
      # Set imageID_string via imageID (it's a copyfield)
      capture = representative_docs.find do |doc|
        # find a child capture with an imageID and a sequence of 1 in order to grab a "front-door" capture where possible
        doc["type_s"] == "http://uri.nypl.org/vocabulary/repository_terms#Capture" && doc["orderInSequence"] == 1 && doc["imageID_string"].present?
      end
      update_hash["imageID"] = capture["imageID_string"] if capture
      
      update_hash
    end.compact
  
    # Attempt the update, and do not escape any errors. We want to let things fail if need be.
    @rsolr.update(data: updates.to_json, headers: { 'Content-Type' => 'application/json' })
    @rsolr.commit
  end

  def get_representative_children_for(uuid, type)
    return [] unless @rsolr && uuid.present? && type.present?

    # The logic here is tricky but is aimed to get only the children we need to make determinations for special fields.
    # For items, we will need one capture where imageID_string is present and orderInSequence:1, plus any other capture available.
    # I think this means we can find all captures with imageID_strings, sort by orderInSequence, and return only 2. 
    if type.downcase == "item"
      response = @rsolr.get("select", params: {
        q: "parentUUID:\"#{uuid}\" AND type_s:Capture",
        fl: "uuid,parentUUID,type_s,orderInSequence,imageID_string",
        sort: "orderInSequence ASC",
        rows: 2
      })["response"]["docs"]

    # For containers and collections, we need:
    # One capture child with the imageID_string
    # One av child if there is an av child available
    # One onsite child if there is an onsite child available, with or without a specific location
    else
      capture = @rsolr.get("select", params: {
        q: "parentUUID:\"#{uuid}\" AND type_s:Capture AND imageID_string:[ * TO * ]",
        fl: "uuid,parentUUID,type_s,orderInSequence,imageID_string",
        sort: "orderInSequence ASC",
        rows: 1
      })["response"]["docs"]

      av_child = @rsolr.get("select", params: {
        q: "parentUUID:\"#{uuid}\" AND ( typeOfResource_mtxt_s:\"sound recording\" OR typeOfResource_mtxt_s:\"moving image\" )",
        fl: "uuid,parentUUID,typeOfResource_mtxt_s",
        rows: 1
      })["response"]["docs"]

      onsite_child_with_location = @rsolr.get("select", params: {
        q: "parentUUID:\"#{uuid}\" AND useRestriction_rtxt_s:(#{NYPL_LOCATIONS.map { |loc| "\"#{loc}\"" }.join(" OR ")})",
        fl: "uuid,parentUUID,useRestriction_rtxt_s",
        rows: 1
      })["response"]["docs"]

      onsite_child_without_location = @rsolr.get("select", params: {
        q: "parentUUID:\"#{uuid}\" AND use_rtxt_s:\"Can be displayed on NYPL premises\" AND -use_rtxt_s:\"Can be used on NYPL website\"",
        fl: "uuid,parentUUID,use_rtxt_s",
        rows: 1
      })["response"]["docs"]

      [capture, av_child, onsite_child_with_location, onsite_child_without_location].flatten
    end
  end

  def update_index_and_delete_empty_parents(new_document)
    return unless @rsolr

    # before we commit the current doc, grab the old document for the item    
    old_document = get_doc(new_document['uuid'])['docs'].first

    # Add/update the new documents
    @rsolr.add new_document
    @rsolr.commit

    # Cleanup old documents if they no longer have children.
    if old_document && old_document['parentUUID'].present?
      # Delete old non-matching parentUUIDs
      old_uuids_to_process = old_document['parentUUID'] - new_document['parentUUID']

      old_uuids_to_process.each do |uuid|
        old_parent = get_doc(uuid)['docs'].first
        
        # Delete the doc entirely if it no longer has children.
        if get_number_of_children_for_parent_uuid(uuid) == 0
          remove_doc_for(uuid)

        # Otherwise, because at least one item is no longer beneath the old parent, we should recalculate the parent information
        else
          update_key_fields(old_parent)
        end
      end
    end
  end

  # remove all captures not updated in current run to ensure bad captures are deleted -- use wisely!
  def delete_unseen_captures_below(item_uuid, seen_uuids)
    return unless @rsolr

    query = 'type_s:Capture AND immediateParent_s:"' + item_uuid + '"'

    # Fetch the initial response to determine the total number of results
    resp = @rsolr.get('select', params: { q: query, rows: 0 })

    unless resp['response']
      raise "Bad response from Solr for immediateParent_s:#{item_uuid}."
    end

    total_results = resp['response']['numFound']
    deletes = false

    # Calculate the total pages to loop through
    total_pages = (total_results + 249) / 250

    # Initialize variables for pagination
    page = 0

    while page <= total_pages do
      break if total_results == 0
      # Set the start parameter for pagination
      start = page * 250

      # Fetch documents from Solr with pagination
      response = @rsolr.get('select', params: { q: query, start: start, rows: 250 })

      unless response['response']
        raise "Bad response from Solr for immediateParent_s:#{item_uuid}, page #{page}."
      end

      # Loop through the Solr response and delete if UUID not in seen_uuids
      response['response']['docs'].each do |doc|
        unless seen_uuids.include?(doc['uuid'])
          Delayed::Worker.logger.info("Deleting capture with UUID: #{doc['uuid']}", uuid: item_uuid)
          @rsolr.delete_by_id(doc['uuid'])
          deletes = true
        end
      end

      # commit deletes for this loop ; depending on performance we may want to adjust this to commit after x number of deletions.
      @rsolr.commit if deletes

      page += 1
    end
  end


  # Assuming you have configured RSolr in your Rails application
  def update_solr_documents(solr_docs)
    # Extract unique UUIDs from the array of Solr documents
    uuids_to_check = solr_docs.map { |doc| doc[:uuid] }.uniq

    # Query Solr for existing documents with the specified UUIDs
    existing_documents = retrieve_existing_documents(uuids_to_check)

    # Filter the Solr documents to post only those that have matching existing documents
    documents_to_post = solr_docs.select { |doc| existing_documents.any? { |existing_doc| existing_doc['uuid'] == doc[:uuid] } }

    # Build the json payload with current timestamps included
    docs = []
    documents_to_post.each do |doc|
      doc["dateIndexed_s"] = RepoSolrDoc.get_datetime_s
      doc["dateIndexed_dt"] = RepoSolrDoc.get_datetime_dt
      docs << doc
    end

    single_field_update_for(docs)
  end

  # Assuming you have configured RSolr in your Rails application
  def retrieve_existing_documents(uuids)
    # Assuming 'uuid' is the unique key for Solr documents
    solr_query = "uuid:(#{uuids.map { |uuid| "\"#{uuid}\"" }.join(' OR ')}) AND title_mtxt_s:[* TO *]"

    # Execute the Solr query and retrieve the matching documents
    solr_response = @rsolr.get('select', params: { q: solr_query, rows: uuids.length, fl: "uuid" })

    # Extract the documents from the Solr response
    solr_documents = solr_response['response']['docs']

    solr_documents
  end

  def single_field_update_for(unsafe_docs_array)
    # Only allow select params through. Might need to adjust these as requirements change.
    permitted_attributes = [:uuid, :field_name, :field_value, :dateIndexed_s, :dateIndexed_dt]

    # Permit only the allowed attributes for each instance
    permitted_params_array = unsafe_docs_array.map { |params| params.permit(permitted_attributes).to_h }

    # Send docs to solr.
    # Build the JSON payload for the partial update
    update_json = []
    permitted_params_array.each do |data_row|
      field_name          = data_row[:field_name]
      new_field_value     = data_row[:field_value]
      date_indexed_s      = data_row[:dateIndexed_s]
      date_indexed_dt     = data_row[:dateIndexed_dt]

      # add docs to the update json array
      update_json << { uuid: data_row[:uuid], field_name => { set: new_field_value },
                                         "dateIndexed_s" => { set: date_indexed_s },
                                         "dateIndexed_dt" => { set: date_indexed_dt } }
    end

    @rsolr.update(data: update_json.to_json, headers: { 'Content-Type' => 'application/json' })
    @rsolr.commit
  end
end
