# frozen_string_literal: false

# This comes from https://jira.nypl.org/browse/DR-3740

# We need to precache some image derivatives

# How to run: bundle exec ruby ./scripts/one-offs/DR-3740-precache-images/precache_images.rb YOUR-COLLECTION-UUID-HERE

require File.expand_path(File.join(File.dirname(__FILE__), '..', '..', '..', 'config', 'environment'))

require 'rsolr'
require 'net/http'
require 'uri'
require 'time'

solr = RSolr.connect url: ENV['REPO_SOLR_URL']

parent_uuid = ARGV[0] # Example, '79d4a650-c52e-012f-67ad-58d385a7bc34'
rows_per_page = 500

# Benchmark tracking
total_elapsed = 0.0
processed = 0

# Helper to fetch a URL and return time taken (or nil if error)
def fetch_url(url)
  uri = URI(url)
  start_time = Time.now
  res = Net::HTTP.get_response(uri)
  elapsed = Time.now - start_time
  status = res.is_a?(Net::HTTPSuccess) ? 'OK' : "#{res.code} #{res.message}"
  puts "#{uri.path} → #{status} (#{elapsed.round(2)}s)"
  elapsed
rescue => e
  puts "#{uri.path} → ERROR (#{e.message})"
  nil
end

# Initial query just to get total number of matches
initial_response = solr.get 'select', params: {
  q: "parentUUID:\"#{parent_uuid}\" AND type_s:Capture",
  fl: 'imageID_string',
  sort: 'sortString_sort asc',
  rows: 0  # only want this for the count
}

total_docs = initial_response.dig('response', 'numFound') || 0
num_pages = (total_docs.to_f / rows_per_page).ceil

puts "Found #{total_docs} imageID_string values across #{num_pages} pages"
puts "-" * 60

# Loop through each page of results
(0...num_pages).each do |page|
  start = page * rows_per_page
  puts "Fetching page #{page + 1} of #{num_pages} (start=#{start})"

  response = solr.get 'select', params: {
    q: "parentUUID:\"#{parent_uuid}\" AND type_s:Capture",
    fl: 'imageID_string',
    sort: 'sortString_sort asc',
    rows: rows_per_page,
    start: start
  }

  docs = response.dig('response', 'docs') || []

  docs.each do |doc|
    image_id = doc['imageID_string']
    next unless image_id

    puts "Processing image ID: #{image_id}"
    image_start = Time.now
    
    # These are the sizes I think are most commonly used by DCFL, but wondering if there are others we should include.
    # Each new call naturally ups the processing time. 
    urls = [
      "https://#{"qa-" if Rails.env != 'production'}iiif.nypl.org/iiif/2/#{image_id}/full/!300,300/0/default.jpg",
      "https://#{"qa-" if Rails.env != 'production'}iiif.nypl.org/iiif/2/#{image_id}/full/!760,760/0/default.jpg"
    ]

    urls.each { |url| fetch_url(url) }

    elapsed = Time.now - image_start
    total_elapsed += elapsed
    processed += 1
    avg = total_elapsed / processed
    remaining = 4_000_000 - processed
    est_remaining_time = remaining * avg
    eta_hours = est_remaining_time / 3600

    puts "Done in #{elapsed.round(2)}s | Avg: #{avg.round(2)}s"
    puts "ETA for 4M: #{eta_hours.round(2)} hours"
    puts "-" * 60
  end
end

