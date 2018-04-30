require 'uri'
require 'http'
require 'rsolr'

class RelsExtIndexClient
  def initialize(options = {})
    # http://qa01-solr.repo.nypl.org:8080/solr-3.5/repoRels/
    @solr = RSolr.connect url: Rails.application.secrets.rels_ext_solr_url
    @solr_params = { wt: :ruby, q: '*:*', deftype: 'lucene' }
  end
  
  def post_solr_doc(uuid, rels_ext)
    old_doc = self.get_doc(uuid)
    new_doc = self.generate_fresh_solr_doc(uuid, rels_ext)
    # remove_childless_parents(old_doc, new_doc)
    @solr.add new_doc
    @solr.commit
  end
  
  def get_doc(uuid)
    @solr_params[:q] = "uuid:#{uuid}"
    resp = @solr.get 'select', :params => @solr_params
    resp["response"] if resp["response"]
  end
  
  def generate_fresh_solr_doc(uuid, rels_ext)
    @solr_params[:q] = "uuid:#{uuid}"
    @solr.get 'select', :params => @solr_params
    doc = { uuid: uuid }
    # mods_st - mods as string, pulled from mods endpoint for uuid
    # firstInSequence - straight uuid, pulled from rels_ext for uuid, e.g., <nyplrepo:firstInSequence rdf:resource="info:fedora/uuid:2b843cd0-42b9-0134-149c-00505686a51c"/>
    # immediateParent_s - self.get_immediate_parent
    # isPartOfSequence - 
    # lastUpdate_dt - date today
    # orderInSequence - 
    # parentUUID -- list of all parent uuids in order UP THE TREE
    # title_mtxt - array of string titles
    # totalInSequence - number
    # type_s - e.g., http://uri.nypl.org/vocabulary/repository_terms#Capture
    # uuid - string 
  end
  
  def get_immediate_parent(rels_ext_document)
    # straight uuid, COMPLICATED, but parsed based on lots of stuff. 
  end
  
  def process_hierarchy(rels_ext_document)
  end
  
  def remove_childless_parents(old_doc, new_doc)
    query = 'uuid:12345'
    @solr.delete_by_query query
    @solr.commit
  end
  #
  private
  
  def get_solr_doc(uuid, options = {})
    # response = @solr.get()
    response = @solr.paginate options[:page], options[:per_page], 'select', :params => @solr_params
    if response
      response
    else
      nil
    end
  end
end
