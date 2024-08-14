# frozen_string_literal: false

# This comes from https://jira.nypl.org/browse/DR-3114

# We need to update all records in the repoapi index to include the rootCollectionUUID_string field value, copied from rootCollectionUUID_s.

# How to run (adjust solr url to the solr of your choice): ruby ./scripts/one-offs/DR-3114-add-root-collection-uuid-string/add_root_collection_uuid_string.rb http://10.225.133.217:8983/solr/repoapi

require File.expand_path(File.join(File.dirname(__FILE__), '..', '..', '..', 'config', 'environment'))
require 'rsolr'

solr = RSolr.connect url: ARGV[0]

solr_params = {
    q: 'rootCollectionUUID_s:[* TO *] AND -rootCollectionUUID_string:[* TO *]',
    rows: 1000
}

response = solr.get 'select', params: solr_params

total_found = response['response']['numFound']
total_count = 0

while total_count <= total_found do
  update_json = []
  response = solr.get 'select', params: solr_params
  response['response']['docs'].each do |doc|
    puts doc['uuid']
    update_json << { uuid: doc['uuid'],
    "dateIndexed_s" => { set: RepoSolrDoc.get_datetime_s },
    "dateIndexed_dt" => { set: RepoSolrDoc.get_datetime_dt } }
  end
      
  solr.update(data: update_json.to_json, headers: { 'Content-Type' => 'application/json' })
  solr.commit
  total_count += update_json.count
  puts "Updated #{total_count} of #{total_found} documents."
  puts "Going back for more ..."

  begin
    solr = RSolr.connect url: ARGV[0]
  rescue Exception => e
    # Refresh the solr connction in case of timeouts
    random_sleep = rand(1..5)
    sleep(random_sleep)
    solr = RSolr.connect url: ARGV[0]
  end 
end

puts "Script finished!"