# frozen_string_literal: true

require 'http'
require 'nokogiri'

class MMSClient
  def initialize(options = {})
    @url = options[:mms_url]
    @basic_username = options[:user_name]
    @basic_password = options[:password]
  end

  def mods_for(uuid)
    make_request_for('mods', uuid)
  end

  def rights_for(uuid)
    make_request_for('rights', uuid)
  end

  def rels_ext_for(uuid)
    make_request_for('rels_ext', uuid)
  end

  def full_rels_ext_solr_docs_for(uuid)
    make_request_for('full_rels_ext_solr_docs', uuid)
  end

  def dublin_core_for(uuid)
    make_request_for('dc', uuid)
  end
  
  # Returns on this level solr doc
  def repo_doc_for(uuid)
    string_response = make_request_for('repo_solr_doc', uuid)
    string_response = "[" + string_response + "]"
    doc_array = convert_to_json_docs(string_response) if string_response
    doc_array.first
  end

  # Returns repoapi solr docs for this level and all ancestors. 
  def repo_docs_for(uuid)
    string_response = make_request_for('repo_solr_docs', uuid)
    convert_to_json_docs(string_response) if string_response
  end

  # Takes the UUID of an Item & returns an Array of hashes that looks like:
  # [{image_uuid: '123-456', image_id: '1234'}]
  def captures_for_item(uuid)
    response = []
    api_response = make_request_for('get_captures', uuid, { showAll: 'true' })
    capture_nodes = Nokogiri::XML(api_response).css('capture')

    capture_nodes.each do |capture_node|
      response << { image_id: capture_node.css('image_id').text, uuid: capture_node.css('uuid').text }
    end

    response
  end

  private

  # This DRYs up the pattern of making a request and throwing an exception for bad responses
  #   - A 410 response means the capture is part of a deleted Item.
  def make_request_for(export_type, uuid, params = {})
    response = authed_request.get(export_url_for(export_type, uuid), params: params)

    # Return nil for things that have moved permanently. This will allow the update to go through in a limited fashion.
    if response.code == 410
      nil

    # otherwise, throw an error
    elsif response.code >= 400
      throw RuntimeError.new("Error getting #{export_type} for UUID #{uuid}: #{response.code} #{response}")
    else
      response.to_s
    end
  end

  # Builds a URL like http://metadata.nypl.org/exports/mods/123-456
  def export_url_for(export_type, uuid)
    "#{@url}/exports/#{export_type}/#{uuid}"
  end

  def authed_request
    HTTP.basic_auth(user: @basic_username, pass: @basic_password)
  end
  
  def convert_to_json_docs(string_response)
    if string_response 
      json_docs = JSON.parse(string_response)
      json_docs.each do |json_response|
        json_response = json_response.except('sortString_sort','mainTitle_sort','shelfLocator_mtxt_str','title_mtxt_str','genre_mtxt_str','placeTerm_mtxt_str','mods_st_str','use_rtxt_str','publisher_mtxt_str','rights_st_str','rightsNotes_rtxt_str','parentUUID_str','sortString_str','original_filename_str','roleTerm_mtxt_str','note_mtxt_str','namePart_mtxt_str','extent_mtxt_str','mainTitle_st_str','useStatementText_rtxt_str','firstInSequence_str','typeOfResource_mtxt_str','useStatementURI_rtxt_str','physicalLocation_mtxt_str','geographic_mtxt_str','topic_mtxt_str','subtitle_mtxt_str','languageTerm_mtxt_str','form_mtxt_str','temporal_mtxt_str','name_mtxt_str','accessCondition_mtxt_str','partnumber_mtxt_str','scriptTerm_mtxt_str','tableOfContents_mtxt_str','titleinfo_mtxt_str','partname_mtxt_str','issuance_mtxt_str','edition_mtxt_str','occupation_mtxt_str','affiliation_mtxt_str','dateother_mtxt_str','classification_mtxt_str','useRestriction_rtxt_str','identifier_idx_local_brightcove_pid_str','identifier_local_brightcove_pid_str','identifier_idx_local_brightcove_key_str','identifier_local_brightcove_key_str','identifier_idx_local_video_id_str','identifier_local_video_id_str','recordContentSource_mtxt_str','recordOrigin_mtxt_str','geograp,hiccode_mtxt_str')
        singles = ['uuid','mods_st', 'rights_st','yearBegin_dt','rootCollection_rootCollectionUUID_s','immediateParent_s','rootCollectionUUID_s','rootCollection_s','numItems_s','dateIndexed_s','yearEnd_dt','parentUUIDSort_s','numSubCollections_s','numItems_s','firstInSequence','isPartOfSequence','orderInSequence','totalInSequence','sortString','sortString_sort','imageID','dateDigitized_dt','type_s','highResLink','mainTitle_st','immediateParentUUID_s','numSubCollections_s','numItems_s','mainTitle_s','keyDate_st','mainTitle_lit_idx','mainTitle_sort','mainTitle_st','mets_alto','mods_st','rights_st']
        singles.each do |s|
          if json_response[s].present? && json_response[s].class == Array
            json_response[s] = json_response[s].first
          end
        end
        if json_response["dateDigitized_dt"].present? && json_response["dateDigitized_dt"].scan(".").present?
          json_response["dateDigitized_dt"] = json_response["dateDigitized_dt"].split(".")[0] + "Z"
        end
        
        begin
          json_response["yearBegin_dt"] = Time.parse(json_response["yearBegin_dt"]).utc.iso8601 if json_response["yearBegin_dt"]
          json_response["yearEnd_dt"] = Time.parse(json_response["yearEnd_dt"]).utc.iso8601 if json_response["yearEnd_dt"]
        rescue Exception => e
          # if anything goes wrong, set to nil so we can still post. 
          json_response["yearBegin_dt"] = nil
          json_response["yearEnd_dt"] = nil
        end
      end
      json_docs
    end
  end
end
