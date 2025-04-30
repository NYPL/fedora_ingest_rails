# frozen_string_literal: false

# This comes from https://jira.nypl.org/browse/DR-3577

# We need to update all records in the repoapi index to include data for our news fields needed for DCF. 

# How to run: bundle exec ruby ./scripts/one-offs/DR-3577-script-to-update-titles-and-dates/add_data_for_titles_and_dates.rb
# You can optionally add a type as an argument if you want to run through only Items, Containers, or Collections, e.g., 
# -- bundle exec ruby ./scripts/one-offs/DR-3577-script-to-update-titles-and-dates/add_data_for_titles_and_dates.rb Item

require File.expand_path(File.join(File.dirname(__FILE__), '..', '..', '..', 'config', 'environment'))

require 'rsolr'
require 'nokogiri'
require 'date'

solr = RSolr.connect(url: ENV['REPO_SOLR_URL']) 

type = ARGV[0].present? ? ARGV[0] : Item

total_count = 0

def fetch_docs_from_solr(solr, type)
  solr.get('select', params: {
    q: "-fullMainTitle_mtxt:[ * TO * ] AND type_s:#{type} AND mainTitle_st:[ * TO * ]",
    fl: "mods_st, yearBegin_dt, yearEnd_dt, uuid, fullMainTitle_mtxt, type_s, mainTitle_st",
    rows: 2000
  }).dig('response', 'docs')
end

def extract_title_from_mods(mods_xml)
  ndoc = Nokogiri::XML(mods_xml)
  ndoc.remove_namespaces!

  mods = ndoc.root
  title_infos = mods.xpath('titleInfo')

  # Pick the primary only if it has non-empty children
  title_info = title_infos.find do |ti|
    usage = ti['usage']
    has_real_content = ti.element_children.any? { |e| !e.inner_text.strip.empty? }
    usage == 'primary' && has_real_content
  end

  # If no good primary, fall back to first titleInfo with content
  title_info ||= title_infos.find do |ti|
    ti.element_children.any? { |e| !e.inner_text.strip.empty? }
  end

  return '' unless title_info

  title = ''

  title_info.element_children.each do |e|
    next if e.inner_text.strip.empty?

    case e.name
    when 'nonSort'
      title += "#{e.inner_text} "
    when 'title'
      title += e.inner_text
    when 'partNumber', 'partName'
      title = tidy(title)
      title += title.match?(/[\.,;:!\?]$/) ? " #{e.inner_text}" : ", #{e.inner_text}"
    when 'subTitle'
      title = tidy(title)
      title += title.match?(/[\.,;:!\?]\s*$/) ? " #{e.inner_text}" : ": #{e.inner_text}"
    end
  end

  tidy(title)
end

def tidy(text)
  text.gsub(/[\n\r]/, ' ').squeeze(' ').strip
end

def extract_year(datetime_str)
  return nil if datetime_str.nil? || datetime_str.empty?
  DateTime.parse(datetime_str).year rescue nil
end

# Main loop
loop do
  docs = fetch_docs_from_solr(solr, type)
  break if docs.empty?
  
  update_json = []

  docs.each do |doc|
    title = extract_title_from_mods(doc['mods_st'])
    year_begin = extract_year(doc['yearBegin_dt'])
    year_end = extract_year(doc['yearEnd_dt'])
    
    update_json << { uuid: doc['uuid'],
      "dateIndexed_s" => { set: RepoSolrDoc.get_datetime_s },
      "dateIndexed_dt" => { set: RepoSolrDoc.get_datetime_dt },
      "fullMainTitle_mtxt" => { set: title },
      "yearBegin" => { set: year_begin }, 
      "yearEnd" => { set: year_end } 
    }
  end
  
  puts "-" * 40
  puts "SAMPLE: #{update_json.first}"
  solr.update(data: update_json.to_json, headers: { 'Content-Type' => 'application/json' })
  solr.commit
  total_count += update_json.count
  
  puts "Updated #{update_json.count} documents, #{total_count} total."
end
