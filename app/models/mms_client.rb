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

  # Takes the UUID of an Item & returns an Array of hashes that looks like:
  # [{image_uuid: '123-456', image_id: '1234'}]
  def captures_for_item(uuid)
    response = []
    api_response = make_request_for('get_captures', uuid, {showAll: 'true'})
    capture_nodes = Nokogiri::XML(api_response).css('capture')

    capture_nodes.each do |capture_node|
      response << { image_id: capture_node.css('image_id').text, uuid: capture_node.css('uuid').text }
    end

    response
  end

  private

  # This DRYs up the pattern of making a request and throwing an exception for bad trsponses
  def make_request_for(export_type, uuid, params = {})
    response = authed_request.get(export_url_for(export_type, uuid), params: params)
    
    # If record has been deleted in MMS remove it from RELS_EXT index because no one else will.
    if response.code == 410
      rels_ext_index_client = RelsExtIndexClient.new(rels_ext_solr_url: Rails.application.secrets.rels_ext_solr_url)
      rels_ext_index_client.remove_doc_for(uuid)
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
