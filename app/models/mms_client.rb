require 'http'

class MMSClient
  def initialize
    @url = Rails.application.secrets.mms_url
    @basic_username = Rails.application.secrets.mms_http_basic_username
    @basic_password = Rails.application.secrets.mms_http_basic_password
  end

  def mods_for(uuid)
    authed_request.get(mms_export_of('mods', uuid)).to_s
  end

  def rights_for(uuid)
    authed_request.get(mms_export_of('rights', uuid)).to_s
  end
private

  # Builds a URL like http://metadata.nypl.org/exports/mods/123-456
  def mms_export_of(export_type, uuid)
    "#{@url}/exports/#{export_type}/#{uuid}"
  end

  def authed_request
    HTTP.basic_auth(:user => @basic_username, :pass => @basic_password)
  end
end
