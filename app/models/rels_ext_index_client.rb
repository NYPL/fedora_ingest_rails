# frozen_string_literal: true

require 'uri'
require 'http'
require 'rsolr'

class RelsExtIndexClient
  def initialize(_options = {})
    @solr = RSolr.connect url: Rails.application.secrets.rels_ext_solr_url
    @solr_params = { wt: :ruby, q: '*:*', deftype: 'lucene' }
  end

  def post_solr_doc(_uuid, solr_docs_array)
    json_docs = JSON.parse(solr_docs_array)
    json_docs.each { |doc| doc['lastUpdate_dt'] = Time.now.utc.iso8601 }
    @solr.add json_docs
  end

  def get_doc(uuid)
    @solr_params[:q] = "uuid:#{uuid}"
    resp = @solr.get 'select', params: @solr_params
    resp['response']
  end

  def remove_doc_for(uuid)
    @solr.delete_by_query "uuid:#{uuid}"
  end

  def commit_index_changes
    @solr.commit
  end
end
