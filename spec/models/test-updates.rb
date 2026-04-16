# 1. Initialize the MMS Client
mms_client = MmsClient.new(
  mms_url: Rails.application.config.mms_url,
  user_name: Rails.application.config.mms_http_basic_username,
  password: Rails.application.config.mms_http_basic_password
)

# 2. Initialize the Solr Client
repo_solr = RepoSolrClient.new

# 3. Set your target Item UUID here
item_uuid = 'YOUR-ITEM-UUID-HERE'

# 4. Mock the seen_uuids array (empty means it evaluates ALL child captures)
seen_uuids = []

# --- DRY RUN LOGIC ---
rsolr = repo_solr.instance_variable_get(:@rsolr)
query = "type_s:Capture AND immediateParent_s:\"#{item_uuid}\""

# Fetch up to 10,000 child captures using the lightweight field list
response = rsolr.get('select', params: { q: query, rows: 10000, fl: 'uuid,imageID_string' })
docs = response.dig('response', 'docs') || []

puts "Found #{docs.count} captures beneath Item #{item_uuid}"
puts "-" * 50

docs.each do |doc|
  uuid = doc['uuid']
  
  if seen_uuids.include?(uuid)
    puts "[SKIPPED] #{uuid} is in seen_uuids."
    next
  end

  # Check MMS rights
  rights = mms_client.rights_for(uuid)

  if rights.nil?
    puts "[WOULD DELETE] #{uuid} | Reason: MMS returned nil (likely 410 Gone)."
  elsif rights.include?("No uses specified.")
    puts "[WOULD DELETE] #{uuid} | Reason: Rights string contains 'No uses specified.'"
  else
    puts "[KEEPING]      #{uuid} | Reason: Has valid uses specified in MMS."
  end
end

puts "-" * 50
puts "Dry run complete."
