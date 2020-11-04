# frozen_string_literal: true

# Eventually, we need to make the switch to retire the RelsExtIndexClient class. -TODO: KAK, 4/2020
# This handles all logic related to building and saving index documents. 
require 'uri'
require 'http'
require 'rsolr'

class RepoSolrClient
  def initialize(_options = {})
    if Rails.env != 'test'
      @repo_solr_client = RSolr.connect url: Rails.application.secrets.repo_solr_url
      @repo_solr_params = { wt: :ruby, q: '*:*' }
    end
  end

  def add_docs_to_solr(solr_docs_array)
    if @repo_solr_client
      @repo_solr_client.add solr_docs_array
    end
  end

  def get_doc(uuid)
    if @repo_solr_client
      @solr_params = { q: "uuid:#{uuid}" }
      resp = @repo_solr_client.get 'select', params: @solr_params
      resp['response']
    end
  end

  def remove_doc_for(uuid)
    @repo_solr_client.delete_by_query "uuid:#{uuid}" if @repo_solr_client
  end

  def commit_index_changes
    @repo_solr_client.commit if @repo_solr_client
  end
  
  def get_solr_doc_for(uuid)
    mms_client = MMSClient.new(mms_url: Rails.application.secrets.mms_url)
    mms_client.repoapi_solr_doc_for(uuid)
  end
end
