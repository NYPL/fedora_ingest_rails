require 'uri'
require 'http'
require 'rsolr'

class RelsExtIndexClient
  def initialize(options = {})
    @solr = RSolr.connect url: Rails.application.secrets.rels_ext_solr_url
    @solr_params = { wt: :ruby, q: '*:*', deftype: 'lucene' }
  end
  
  def post_solr_doc(uuid, solr_docs_array)
    # old_doc = self.get_doc(uuid)
    # remove_childless_parents(old_doc, new_doc)
    json_docs = JSON.parse(solr_docs_array)
    json_docs.each { |doc| doc['lastUpdate_dt'] = Time.now.utc.iso8601 }
    @solr.add json_docs
    @solr.commit
  end
  
  def get_doc(uuid)
    @solr_params[:q] = "uuid:#{uuid}"
    resp = @solr.get 'select', :params => @solr_params
    resp["response"] if resp["response"]
  end
  
  def remove_childless_parents(old_doc, new_doc)
    query = 'uuid:12345'
    @solr.delete_by_query query
    @solr.commit
  end
end