class RSolr::Connection
  alias :old_setup_raw_request :setup_raw_request

  def setup_raw_request request_context
    raw_request = old_setup_raw_request request_context
    raw_request.basic_auth(ENV['RELS_EXT_USERNAME'], ENV['RELS_EXT_PASSWORD'])
    raw_request
  end
end