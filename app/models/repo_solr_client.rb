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
    else
      @rsolr = RSolr.connect url: 'http://10.225.133.217:8983/solr/repoapi'
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
end
