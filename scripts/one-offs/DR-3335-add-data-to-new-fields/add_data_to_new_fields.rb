# frozen_string_literal: false

# This comes from https://jira.nypl.org/browse/DR-3335

# We need to update all records in the repoapi index to include data for our news fields needed for DCF. 

# How to run: bundle exec ruby ./scripts/one-offs/DR-3335-add-data-to-new-fields/add_data_to_new_fields.rb
# You can optionally add a type as an argument if you want to run through only Items, Containers, or Collections, e.g., 
# -- bundle exec ruby ./scripts/one-offs/DR-3335-add-data-to-new-fields/add_data_to_new_fields.rb Item
# N.B.: This will need to be run one more time after the code is updated in the regular app to add these fields on index. 

require File.expand_path(File.join(File.dirname(__FILE__), '..', '..', '..', 'config', 'environment'))

require 'rsolr'

solr = RSolr.connect(url: ENV['REPO_SOLR_URL']) 

begin
  loop do
    response = solr.get('select', params: {
      q: "-dateIndexed_dt:[#{Date.today.to_time.utc.strftime('%Y-%m-%dT%H:%M:%SZ')} TO *] AND type_s:#{ARGV[0]} AND mainTitle:[ * TO * ]",
      rows: 100 
    })

    docs = response.dig('response', 'docs')

    break if docs.empty?

    repo = RepoSolrClient.new
    repo.update_key_fields(docs)

    puts "Updated #{docs.size} documents of #{response.dig('response', 'numFound')}"
  end

  puts "All outdated documents have been updated."
rescue StandardError => e
  puts "An error occurred: #{e.message}"
end
