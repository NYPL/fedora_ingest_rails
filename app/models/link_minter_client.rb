require 'http'

class LinkMinterClient
  def initialize(options = {})
    @url = options[:link_minter_url]
    @basic_username = options[:user_name]
    @basic_password = options[:password]
  end
  
  def fetch_permalink(not_permalink_string)
  end

  private
  
  def authed_request
    HTTP.basic_auth(user: @basic_username, pass: @basic_password)
  end
end
