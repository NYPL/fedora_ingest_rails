# frozen_string_literal: false

# This comes from https://jira.nypl.org/browse/DR-3335

# We need to update all records in the repoapi index to include data for our news fields needed for DCF. 

# How to run: ruby ./scripts/one-offs/DR-3335-add-data-to-new-fields/add_data_to_new_fields.rb
# N.B.: This will need to be run one more time after the code is updated in the regular app to add these fields on index. 

require File.expand_path(File.join(File.dirname(__FILE__), '..', '..', '..', 'config', 'environment'))

require 'rsolr'

# Connect to Solr
solr = RSolr.connect(url: ENV['REPO_SOLR_URL']) # Replace with your favorite solr url. 

begin
  loop do
    # Query Solr for documents to update
    response = solr.get('select', params: {
      q: "-imageID_string:[* TO *] AND -containsAVMaterial:[* TO *] AND -containsOnSiteMaterial:[* TO *] AND -containsMultipleCaptures:[* TO *] AND -type_s:Capture AND mainTitle:[ * TO * ]",
      # q: "-dateIndexed_dt:[#{Date.today.to_time.utc.strftime('%Y-%m-%dT%H:%M:%SZ')} TO *] AND type_s:#{ARGV[0]} AND mainTitle:[ * TO * ]",
      rows: 100 #,
      # fl: 'uuid,dateIndexed_dt,type_s,itemsCount,mainTitle'
    })

    docs = response.dig('response', 'docs')

    # Break the loop if no documents are found
    break if docs.empty?

    # Update the docs using Repo Solr Client method
    repo = RepoSolrClient.new
    repo.update_key_fields(docs)

    # Log progress
    puts "Updated #{docs.size} documents of #{response.dig('response', 'numFound')}"
  end

  puts "All outdated documents have been updated."
rescue StandardError => e
  puts "An error occurred: #{e.message}"
end
