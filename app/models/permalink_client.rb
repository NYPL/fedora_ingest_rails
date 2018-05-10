require 'uri'
require 'http'
require 'net/http/digest_auth'

class PermalinkClient
  def initialize(options = {})
    @uuid = options[:uuid]
    @base_links_url = ENV['LINK_BASE_URL']
    @basic_username = ENV['LINK_USERNAME']
    @basic_password = ENV['LINK_PASSWORD']
    @logger = NyplLogFormatter.new(STDOUT)
  end

  def fetch_or_mint_permalink(not_permalink_string)
    # `/record` will find or create a shortened link.
    # There's no need to manually look it up.
    # The providing the same uuid for a given URL makes the shortened URL returned deterministically the same.
    uri = URI.parse "#{@base_links_url}/link-admin/record?url=#{not_permalink_string}&username=fedora_ingest_rails&redirect=false&uuid=#{@uuid}"
    res = authed_request(uri,'POST')
    if res.code.eql? "201"
      @logger.info("Found or created permalink", url: not_permalink_string, mintedCode: res.body.to_s)
      return "#{@base_links_url}/#{res.body.to_s}"
    else
      throw RuntimeError.new("Error minting link from link minter. #{res.code}: #{res.body}")
    end

  end

  private

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
