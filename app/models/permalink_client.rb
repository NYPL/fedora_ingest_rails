require 'uri'
require 'http'
require 'net/http/digest_auth'

class PermalinkClient
  def initialize(options = {})
    @base_links_url = ENV['LINK_BASE_URL']
    @lookup_url = ENV['LINK_LOOKUP_URL']
    @minter_url = ENV['LINK_MINTER_URL']
    @basic_username = ENV['LINK_USERNAME']
    @basic_password = ENV['LINK_PASSWORD']
  end
  
  def fetch_or_mint_permalink(not_permalink_string)
    link_id = fetch_permalink(not_permalink_string) || mint_permalink(not_permalink_string)
    @base_links_url + link_id
  end

  private
  
  def fetch_permalink(not_permalink_string)
    uri = URI.parse "#{@lookup_url}?url=#{not_permalink_string}"
    res = authed_request(uri)
    
    if res.code.eql? "200"
      a = JSON.parse(res.body)
      if a["linkRecord"].is_a?(Hash)
        return a["linkRecord"]["linkID"]
      elsif a["linkRecord"].is_a?(Array)
        # link minter service does not control for uniqueness of urls.
        return a["linkRecord"][0]["linkID"].to_s
      end
    else
      throw RuntimeError.new("Error fetching link from link minter")
    end
  end

  def mint_permalink(not_permalink_string)
    uri = URI.parse "#{@minter_url}?url=#{not_permalink_string}&username=link_client"
    res = authed_request(uri,'POST')
    if res.code.eql? "201"
      return res.body.to_s
    else
      throw RuntimeError.new("Error minting link from link minter")
    end
  end
  
  def authed_request(uri, http_verb='GET')
    uri.user = @basic_username
    uri.password = @basic_password
  
    h = Net::HTTP.new uri.host, uri.port
    req = Net::HTTP::Get.new uri.request_uri
    res = h.request req
    
    digest_auth = Net::HTTP::DigestAuth.new
    auth = digest_auth.auth_header uri, res['www-authenticate'], http_verb # 'GET' or 'POST'
    req = http_verb == 'POST' ? Net::HTTP::Post.new(uri.request_uri) : Net::HTTP::Get.new(uri.request_uri)
    req.add_field 'Authorization', auth
    
    h.request req
  end
end
