require 'http'
require 'nokogiri'

class MMSClient
  def initialize(options = {})
    @url = options[:mms_url]
    @basic_username = options[:user_name]
    @basic_password = options[:password]
  end

  def mods_for(uuid)
    authed_request.get(mms_export_of('mods', uuid)).to_s
  end

  def rights_for(uuid)
    authed_request.get(mms_export_of('rights', uuid)).to_s
  end

  def rels_ext_for(uuid)
    authed_request.get(mms_export_of('rels_ext', uuid)).to_s
  end

  def dublin_core_for(uuid)
    authed_request.get(mms_export_of('dc', uuid)).to_s
  end

  # Takes the UUID of an Item & returns an Array of hashes that looks like:
  # [{image_uuid: '123-456', image_id: '1234'}]
  def captures_for_item(uuid)
    response = []
    api_response = authed_request.get(mms_export_of('get_captures', uuid), params: { showAll: 'true' }).to_s
    capture_nodes = Nokogiri::XML(api_response).css('capture')

    capture_nodes.each do |capture_node|
      response << { image_id: capture_node.css('image_id').text, uuid: capture_node.css('uuid').text }
    end

    response
  end

  private

  # Builds a URL like http://metadata.nypl.org/exports/mods/123-456
  def mms_export_of(export_type, uuid)
    "#{@url}/exports/#{export_type}/#{uuid}"
  end

  def authed_request
    HTTP.basic_auth(user: @basic_username, pass: @basic_password)
  end
end
