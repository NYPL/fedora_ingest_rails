# frozen_string_literal: true

require 'uri'
require 'http'
require 'rsolr'

class RepoSolrClient
  def initialize(_options = {})
    # We don't need to instantiate a repo solr client ... until we do. We mock it in some of our tests. 
    if Rails.env != 'test' || ( Rails.env == 'test' && Rails.application.secrets.repo_solr_url == 'http://fake.com/solr' )
      @rsolr = RSolr.connect url: Rails.application.secrets.repo_solr_url
      @rsolr_params = { wt: :ruby, q: '*:*' }
    end
  end

  def add_docs_to_solr(solr_docs_array, check_parents=false) 
    if @rsolr
      if check_parents == true
        solr_docs_array.each do |doc|
          update_index_and_delete_empty_parents(doc)
        end
      else
        @rsolr.add solr_docs_array
      end
    end
  end

  def get_doc(uuid)
    if @rsolr
      @rsolr_params = { q: "uuid:#{uuid}" }
      resp = @rsolr.get 'select', params: @rsolr_params
      if resp['response']
        resp['response']
      else
        raise "Bad response from solr for uuid:#{uuid}."
      end
    end
  end
  
  def get_number_of_children_for_parent_uuid(uuid)
    if @rsolr
      # Find out how many actual items are beneath this parent.
      @rsolr_params = { q: "parentUUID:\"#{uuid}\" AND type_s:Item" }
      resp = @rsolr.get 'select', params: @rsolr_params
      if resp['response']
        resp['response']['numFound']
      else
        raise "Bad response from solr for parentUUID:#{uuid}."
      end
    end
  end

  def remove_doc_for(uuid)
    @rsolr.delete_by_query "uuid:#{uuid}" if @rsolr
  end

  def commit_index_changes
    @rsolr.commit if @rsolr
  end

  def get_solr_doc_for(uuid)
    mms_client = MMSClient.new(mms_url: Rails.application.secrets.mms_url)
    mms_client.repoapi_solr_doc_for(uuid)
  end
  
  def update_index_and_delete_empty_parents(new_document)
    return unless @rsolr
    
    old_document = get_doc(new_document['uuid'])['docs'].first

    if old_document && old_document['parentUUID'].present?
      # Delete old non-matching parentUUIDs
      old_uuids_to_delete = old_document['parentUUID'] - new_document['parentUUID']
      old_uuids_to_delete.each do |uuid|
        # Only delete the doc if this item is the last to move out beneath the object, or if it's empty already.
        if get_number_of_children_for_parent_uuid(uuid) <= 1
          remove_doc_for(uuid)
        end
      end
    end

    # Add/update the new document
    @rsolr.add new_document
    @rsolr.commit
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
end
