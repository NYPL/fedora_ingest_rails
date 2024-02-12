# frozen_string_literal: false

require 'rsolr'
require File.expand_path(File.join(File.dirname(__FILE__), '..', 'config', 'environment'))

# Solr URL
solr_url = 'http://solr:8983/solr/repoapi'

# Initialize Solr client
solr = RSolr.connect(url: solr_url)

# Query Solr to retrieve documents with dateIndexed_s field
response = solr.get('select', params: { q: '*:*', fl: 'uuid,dateIndexed_s', rows: 1000 })

response['response']['docs'].each do |doc|
  uuid = doc['uuid']
  date_indexed_dt = doc['dateIndexed_s']&.first
  next unless date_indexed_dt
  update_data = [{ uuid: uuid, dateIndexed_dt: { set: date_indexed_dt } }]
  update_params = { params: { commit: true }, data: update_data.to_json }

  response = solr.update(update_params)
  puts response
end

# Enqueue jobs for all page numbers of all docs -- lower priority!
# Job
# get document uuids in batches of 1000
# use date Indexed from doc. If nonexistent or empty, use DateIndexed from db
# Parse to dateIndexed dt
# Update dt or update both s and dt if pulled from db (batches of X?)
# If a failure, go one by one. Enqueue subjobs for failures
## use date Indexed from doc. If nonexistent or empty, use DateIndexed from db
# Parse to dateIndexed dt
# Update dt or update both s and dt if pulled from db
