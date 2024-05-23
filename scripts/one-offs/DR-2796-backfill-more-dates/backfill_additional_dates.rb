# frozen_string_literal: false

# This comes from https://jira.nypl.org/browse/DR-2796

# We've updated a lot of things to have string dates, and we've added a lot of database records for first indexed dates. This should make sure we have actual dates for all first indexed values. 

# How to run: ruby ./scripts/one-offs/DR-2796-backfill-more-dates/backfill_additional_dates.rb YOUR_FAVORITE_SOLR_URL
# e.g. `ruby ./scripts/one-offs/DR-2796-backfill-more-dates/backfill_additional_dates.rb http://10.225.133.217:8983/solr/repoapi`
# It will run for a long time and might need to be restarted a bunch, but as it will work through all solr docs missing dates, that runtime should decrease over time. It is not a problem to start and restart this script. 

require File.expand_path(File.join(File.dirname(__FILE__), '..', '..', '..', 'config', 'environment'))
require 'time'
require 'csv'

def check_missing_indexed_capture_docs(solr_url)
  solr = RSolr.connect(url: solr_url)
  rows_per_page = 250 # Adjust as needed based on your Solr setup
  
  start = 0
  total_results = nil
  missing_uuids = []

  loop do
    # Construct Solr query to find documents missing firstIndexed_dt with a title (prevents looking at deactivated records)
    # We also need to loop first through captures as they are the ones that will have values associated with dates from filestore. 
    query = '-firstIndexed_dt:[* TO *] AND mainTitle:[ * TO * ] AND type_s:Capture'
    
    # Perform Solr search with pagination
    response = solr.get('select', params: {
      q: query,
      fl: 'uuid',
      rows: rows_per_page,
      start: start
    })

    total_results ||= response['response']['numFound']
    
    update_json = []

    # Loop through each document
    response['response']['docs'].each do |doc|
      uuid = doc['uuid']

      # Check if corresponding record exists in RepoSolrDoc
      unless RepoSolrDoc.exists?(uuid: uuid)
        puts "Record with UUID #{uuid} does not exist in the database."
        missing_uuids << uuid
      else
        puts "Records found for #{uuid}. Adding corrected dates to document array."
        
        repo_solr_doc     = RepoSolrDoc.find_by_uuid(uuid)
        index_time_plain  = Time.current
        index_time_s      = RepoSolrDoc.format_as_solr_s(index_time_plain)
        index_time_dt     = RepoSolrDoc.format_as_solr_dt(index_time_plain)
        
        first_indexed_plain = repo_solr_doc.first_indexed.to_time
        first_indexed_s     = first_indexed_plain.iso8601(3)
        first_indexed_dt    = RepoSolrDoc.format_as_solr_dt(first_indexed_plain)
        
        # add docs to the update json array
        update_json << { uuid: uuid, 
                        "firstIndexed_s" => { set: first_indexed_s },
                        "firstIndexed_dt" => { set: first_indexed_dt },
                        "dateIndexed_s" => { set: index_time_s },
                        "dateIndexed_dt" => { set: index_time_dt } }
      end
    end
    
    puts "Posting a batch of #{update_json.count} available updates to solr."
    solr.update(data: update_json.to_json, headers: { 'Content-Type' => 'application/json' })
    solr.commit

    # Move to the next page
    start += rows_per_page
    break if start >= total_results
  end

  # Save missing UUIDs to CSV file
  CSV.open("#{Rails.root}/scripts/one-offs/DR-2796-backfill-more-dates/missing_uuids.csv", 'w') do |csv|
    csv << ['UUID']
    missing_uuids.each { |uuid| csv << [uuid] }
  end

  puts "Missing UUIDs saved to 'missing_uuids.csv' file."
end

def check_missing_indexed_parent_docs(solr_url)
  solr = RSolr.connect(url: solr_url)
  rows_per_page = 250 # Adjust as needed based on your Solr setup
  
  start = 0
  total_results = nil
  missing_parent_uuids = []

  loop do
    # Construct Solr query to find documents missing firstIndexed_dt with a title (prevents looking at deactivated records)
    # Now that we have some captures fixed, we need to fill in missing parent values based on capture dates.
    query = '-firstIndexed_dt:[* TO *] AND mainTitle:[ * TO * ] AND -type_s:Capture'
    
    # Perform Solr search with pagination
    response = solr.get('select', params: {
      q: query,
      fl: 'uuid',
      rows: rows_per_page,
      start: start
    })

    total_results ||= response['response']['numFound']
    
    update_json = []

    # Loop through each document
    response['response']['docs'].each do |doc|
      uuid = doc['uuid']
      
      query = "parentUUID_s:\"#{uuid}\" AND type_s:Capture AND firstIndexed_dt:[ * TO * ]"
      
      capture_response = solr.get('select', params: {
        q: query,
        fl: ['firstIndexed_dt','firstIndexed_s'],
        rows: 1,
        sort: 'sortString_sort ASC'
      })
      
      first_capture_solr_doc = capture_response['response']['docs'].first

      # Check if corresponding record exists in RepoSolrDoc
      unless first_capture_solr_doc
        puts "Capture does not exist for parent uuid #{uuid} in solr."
        missing_parent_uuids << uuid
      else
        puts "Records found for #{uuid}. Adding corrected dates to document array."
        
        index_time_plain  = Time.current
        index_time_s      = RepoSolrDoc.format_as_solr_s(index_time_plain)
        index_time_dt     = RepoSolrDoc.format_as_solr_dt(index_time_plain)
        
        first_indexed_s     = first_capture_solr_doc['firstIndexed_s']
        first_indexed_dt    = first_capture_solr_doc['firstIndexed_dt']
        
        # add docs to the update json array
        update_json << { uuid: uuid, 
                        "firstIndexed_s" => { set: first_indexed_s },
                        "firstIndexed_dt" => { set: first_indexed_dt },
                        "dateIndexed_s" => { set: index_time_s },
                        "dateIndexed_dt" => { set: index_time_dt } }
      end
    end
    
    puts "Posting a batch of #{update_json.count} available updates to solr."
    solr.update(data: update_json.to_json, headers: { 'Content-Type' => 'application/json' })
    solr.commit

    # Move to the next page
    start += rows_per_page
    break if start >= total_results
  end

  # Save missing UUIDs to CSV file
  CSV.open("#{Rails.root}/scripts/one-offs/DR-2796-backfill-more-dates/missing_uuids.csv", 'w') do |csv|
    csv << ['UUID']
    missing_parent_uuids.each { |uuid| csv << [uuid] }
  end

  puts "Missing UUIDs saved to 'missing_uuids.csv' file."
end



# Run against the solr of your choice. 
solr_url = ARGV[0]
check_missing_indexed_capture_docs(solr_url)
check_missing_indexed_parent_docs(solr_url)
