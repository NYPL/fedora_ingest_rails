# frozen_string_literal: false

require 'rsolr'
require File.expand_path(File.join(File.dirname(__FILE__), '..', 'config', 'environment'))

#class DtUpdateJob
#  def initialize(page, per_page)
#    @page = page
#    @per_page = per_page
#  end
#
#  def perform
#    # Call your method with the provided arguments
#    batch_dt_update(@page, @per_page)
#  end
#end

ActiveRecord::Base.logger.level = 2

start_time = Time.now

# Solr URL
#solr_url = 'http://solr:8983/solr/repoapi'
#solr_url = 'http://10.225.131.109:8983/solr/repoapi'
solr_url = 'http://10.225.132.218:8983/solr/repoapi'

# Initialize Solr client
solr = RSolr.connect(url: solr_url)

# Query Solr to retrieve documents with dateIndexed_s field
response = solr.get('select', params: { q: '*:*', fl: 'uuid,dateIndexed_s,firstIndexed_s', rows: 1 })
total_docs = response['response']['numFound']

per_page = 1000
total_pages = (total_docs.to_f / per_page).ceil

page = 0

total_pages.times do
  page += 1
  Delayed::Job.enqueue(DtUpdateJob.new(page, per_page))
end

def batch_dt_update(page, per_page)
  solr_params = { :q => '*:*', :fl =>'uuid,dateIndexed_s,firstIndexed_s', sort: 'firstIndexed_s asc' }
  response = solr.paginate(page, per_page, 'select', :params => solr_params)
  update_data = []

  docs = response['response']['docs']
  docs.each do |doc|
    uuid = doc['uuid']
    date_indexed_dt = doc['dateIndexed_s']&.first
    first_indexed_dt = doc['firstIndexed_s']&.first
    next unless date_indexed_dt
    update = {}
    update[:uuid] = uuid
    update[:dateIndexed_dt] = { set: date_indexed_dt } unless date_indexed_dt.blank?
    update[:firstIndexed_dt] = { set: first_indexed_dt } unless first_indexed_dt.blank?
    update_data << update unless update == { uuid: uuid }
  end

  begin
    update_params = { params: { commit: true }, data: update_data.to_json }
    response = solr.update(update_params)
  rescue StandardError => e
    puts "Got a hiccup: #{e}. Going one by one"
    update_data.each do |datum|
      update_params = { params: { commit: true }, data: datum.to_json }
      begin
        response = solr.update(update_params)
      rescue StandardError => e
        puts "Found the problem: #{e}"
        datum[:firstIndexed_dt] = { set: Time.parse(datum[:firstIndexed_dt]).utc.strftime('%Y-%m-%dT%H:%M:%SZ') }
        update_params = { params: { commit: true }, data: datum.to_json }
        response = solr.update(update_params)
      end
    end
    retry
  end

  puts "at page: #{page} of #{total_pages}"
end

end_time = Time.now
time_elapsed = end_time - start_time
puts "Time elapsed: #{time_elapsed} seconds"

#response = solr.get('select', params: { q: '*:*', fl: 'uuid,dateIndexed_s', rows: 1000 })

#response['response']['docs'].each do |doc|
#  uuid = doc['uuid']
#  date_indexed_dt = doc['dateIndexed_s']&.first
#  next unless date_indexed_dt
#  update_data = [{ uuid: uuid, dateIndexed_dt: { set: date_indexed_dt } }]
#  update_params = { params: { commit: true }, data: update_data.to_json }
#
#  response = solr.update(update_params)
#  puts response
#end

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
