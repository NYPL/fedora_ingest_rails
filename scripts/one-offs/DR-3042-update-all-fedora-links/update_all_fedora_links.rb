# frozen_string_literal: false

# This comes from https://jira.nypl.org/browse/DR-3042

# We need to now update all the links in the link service that point to Fedora and make them point to IIIF instead. 

# How to run: bundle exec ruby ./scripts/one-offs/DR-3042-update-all-fedora-links/update_all_fedora_links.rb

# Test by verifying there are no more links to fedora in the database. 

require File.expand_path(File.join(File.dirname(__FILE__), '..', '..', '..', 'config', 'environment'))

csv_file = File.join(File.dirname(__FILE__), "fedora_links.csv")

CSV.foreach(csv_file, headers: :first_row) do |row|
  file_uuid         = row[0]
  filestore_entry   = ImageFilestoreEntry.where(uuid: file_uuid).first
  full_res_path     = "#{Rails.application.config.iiif_host}/index.php?id=#{filestore_entry.file_id}&t=u"
  highres_permalink = PermalinkClient.new(uuid: file_uuid).fetch_or_mint_permalink(full_res_path)
  puts "Updated permalink for #{file_uuid}, image_id: #{filestore_entry.file_id}, #{full_res_path}"
end

puts "Finished!"
