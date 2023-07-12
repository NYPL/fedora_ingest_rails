# frozen_string_literal: true

require 'http'
require 'nokogiri'

class MMSClient
  def initialize(options = {})
    @url = options[:mms_url]
    @basic_username = options[:user_name]
    @basic_password = options[:password]
  end

  REMOVABLE_FIELDS = [
    'accessCondition_mtxt_str',
    'affiliation_mtxt_str',
    'classification_mtxt_str',
    'dateother_mtxt_str',
    'edition_mtxt_str',
    'extent_mtxt_str',
    'firstInSequence_str',
    'form_mtxt_str',
    'geographic_mtxt_str',
    'geographiccode_mtxt_str',
    'hierarchicalgeographic_mtxt',
    'identifier_idx_local_brightcove_key_str',
    'identifier_idx_local_brightcove_pid_str',
    'identifier_idx_local_video_id_str',
    'identifier_local_brightcove_key_str',
    'identifier_local_brightcove_pid_str',
    'identifier_local_video_id_str',
    'issuance_mtxt_str',
    'languageTerm_mtxt_str',
    'mainTitle_sort',
    'mainTitle_st_str',
    'namePart_mtxt_str',
    'name_mtxt_str',
    'note_mtxt_str',
    'occupation_mtxt_str',
    'original_filename_str',
    'parentUUID_str',
    'partname_mtxt_str',
    'partnumber_mtxt_str',
    'physicalLocation_mtxt_str',
    'placeTerm_mtxt_str',
    'publisher_mtxt_str',
    'recordContentSource_mtxt_str',
    'recordOrigin_mtxt_str',
    'rightsNotes_rtxt_str',
    'rights_st_str',
    'roleTerm_mtxt_str',
    'scriptTerm_mtxt_str',
    'shelfLocator_mtxt_str',
    'sortString_sort',
    'sortString_str',
    'subtitle_mtxt_str',
    'tableOfContents_mtxt_str',
    'temporal_mtxt_str',
    'title_mtxt_str',
    'titleinfo_mtxt_str',
    'topic_mtxt_str',
    'typeOfResource_mtxt_str',
    'useRestriction_rtxt_str',
    'useStatementText_rtxt_str',
    'useStatementURI_rtxt_str',
    'use_rtxt_str'
  ].freeze

  SINGLES = [
    'dateDigitized_dt',
    'dateIndexed_s',
    'firstInSequence',
    'firstIndexed_s',
    'highResLink',
    'identifier_idx_local_brightcove_id',
    'identifier_idx_local_brightcove_key',
    'identifier_idx_local_brightcove_pid',
    'identifier_idx_local_hades_struc_id',
    'identifier_idx_local_image_id',
    'identifier_idx_local_video_id',
    'identifier_local_brightcove_id_string',
    'identifier_local_brightcove_key_string',
    'identifier_local_brightcove_pid_string',
    'identifier_local_video_id_string',
    'identifier_local_photo_order_string',
    'identifier_local_barcode_string',
    'identifier_local_bnumber_string',
    'identifier_local_mss_string',
    'identifier_local_mss_av_string',
    'identifier_local_preservica_id_string',
    'identifier_local_tms_id_string',
    'identifier_local_tms_object_number_string',
    'identifier_local_exhibition_string',
    'identifier_local_catnyp_string',
    'identifier_local_archives_ead_string',
    'identifier_local_mss_er_string',
    'identifier_local_other_string',
    'identifier_local_filename_string',
    'identifier_oclc_string',
    'identifier_lccn_string',
    'identifier_isbn_string',
    'identifier_isrc_string',
    'identifier_isan_string',
    'identifier_issue-number_string',
    'identifier_matrix-number_string',
    'identifier_videorecording-identifier_string',
    'identifier_ismn_string',
    'identifier_iswc_string',
    'identifier_music-plate_string',
    'identifier_music-publisher_string',
    'identifier_issn_string',
    'identifier_issn-l_string',
    'identifier_sici_string',
    'identifier_istc_string',
    'identifier_natgazfid_string',
    'identifier_strn_string',
    'identifier_uri_string',
    'identifier_urn_string',
    'identifier_uuid_string',
    'identifier_local_cms_collection_string',
    'identifier_local_cms_string',
    'identifier_local_AMI_other_string',
    'identifier_local_AMI_primaryID_string',
    'identifier_local_AMI_project_string',
    'identifier_local_brightcove_id',
    'identifier_local_brightcove_key',
    'identifier_local_brightcove_pid',
    'identifier_local_hades_struc_id',
    'identifier_local_image_id',
    'identifier_local_video_id',
    'identifier_local_photo_order',
    'identifier_local_barcode',
    'identifier_local_bnumber',
    'identifier_local_mss',
    'identifier_local_mss_av',
    'identifier_local_preservica_id',
    'identifier_local_tms_object_number',
    'identifier_local_hades',
    'identifier_local_hades_collection',
    'identifier_local_imageid',
    'identifier_local_exhibition',
    'identifier_local_catnyp',
    'identifier_local_archives_ead',
    'identifier_local_mss_er',
    'identifier_local_other',
    'identifier_local_filename',
    'identifier_oclc',
    'identifier_lccn',
    'identifier_isbn',
    'identifier_isrc',
    'identifier_isan',
    'identifier_issue-number',
    'identifier_matrix-number',
    'identifier_videorecording-identifier',
    'identifier_ismn',
    'identifier_iswc',
    'identifier_music-plate',
    'identifier_music-publisher',
    'identifier_issn',
    'identifier_issn-l',
    'identifier_sici',
    'identifier_istc',
    'identifier_natgazfid',
    'identifier_strn',
    'identifier_uri',
    'identifier_urn',
    'identifier_uuid',
    'identifier_local_cms_collection',
    'identifier_local_cms',
    'identifier_local_AMI_other',
    'identifier_local_AMI_primaryID',
    'identifier_local_AMI_project',
    'identifier_idx_local_photo_order',
    'identifier_idx_local_barcode',
    'identifier_idx_local_bnumber',
    'identifier_idx_local_mss',
    'identifier_idx_local_mss_av',
    'identifier_idx_local_preservica_id',
    'identifier_idx_local_tms_object_number',
    'identifier_idx_local_hades',
    'identifier_idx_local_hades_collection',
    'identifier_idx_local_imageid',
    'identifier_idx_local_exhibition',
    'identifier_idx_local_catnyp',
    'identifier_idx_local_archives_ead',
    'identifier_idx_local_mss_er',
    'identifier_idx_local_other',
    'identifier_idx_local_filename',
    'identifier_idx_oclc',
    'identifier_idx_lccn',
    'identifier_idx_isbn',
    'identifier_idx_isrc',
    'identifier_idx_isan',
    'identifier_idx_issue-number',
    'identifier_idx_matrix-number',
    'identifier_idx_videorecording-identifier',
    'identifier_idx_ismn',
    'identifier_idx_iswc',
    'identifier_idx_music-plate',
    'identifier_idx_music-publisher',
    'identifier_idx_issn',
    'identifier_idx_issn-l',
    'identifier_idx_sici',
    'identifier_idx_istc',
    'identifier_idx_natgazfid',
    'identifier_idx_strn',
    'identifier_idx_uri',
    'identifier_idx_urn',
    'identifier_idx_uuid',
    'identifier_idx_local_cms_collection',
    'identifier_idx_local_cms',
    'identifier_idx_local_AMI_other',
    'identifier_idx_local_AMI_primaryID',
    'identifier_idx_local_AMI_project',
    'imageID',
    'imageID_lit',
    'imageID_string',
    'immediateParentUUID_s',
    'immediateParent_s',
    'isPartOfSequence',
    'keyDate_st',
    'mainTitle_lit_idx',
    'mainTitle_s',
    'mainTitle_st',
    'mainTitle_st',
    'mets_alto',
    'mods_st',
    'mods_st',
    'numItems_s',
    'numItems_s',
    'numItems_s',
    'numSubCollections_s',
    'numSubCollections_s',
    'orderInSequence',
    'parentUUIDSort_s',
    'rights_st',
    'rights_st',
    'rootCollectionUUID_s',
    'rootCollection_rootCollectionUUID_s',
    'rootCollection_s',
    'sortString',
    'totalInSequence',
    'type_s',
    'uuid',
    'yearBegin_dt',
    'yearEnd_dt'
  ].freeze

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

  def convert_to_json_docs(string_response)
    if string_response
      json_docs   = JSON.parse(string_response)
      docs_array  = json_docs.class == Array ? json_docs : [ json_docs ]
      new_docs    = []
      
      docs_array.each do |json_response|
        json_response.except!( *REMOVABLE_FIELDS )

        SINGLES.each do |s|
          single = json_response[s]
          json_response[s] = single.first if single.present? && single.class == Array
        end

        date_digitized = json_response['dateDigitized_dt']
        json_response['dateDigitized_dt'] = date_digitized.split('.').first + 'Z' if date_digitized&.include?('.')

        begin
          year_begin = json_response['yearBegin_dt']
          json_response['yearBegin_dt'] = Time.parse(year_begin).utc.iso8601 if year_begin
          year_end = json_response['yearEnd_dt']
          json_response['yearEnd_dt'] = Time.parse(year_end).utc.iso8601 if year_end
        rescue Exception => e
          puts e
          # if anything goes wrong, set to nil so we can still post.
          json_response['yearBegin_dt'] = nil
          json_response['yearEnd_dt'] = nil
        end

        new_docs << json_response
      end

      new_docs
    end
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

end
