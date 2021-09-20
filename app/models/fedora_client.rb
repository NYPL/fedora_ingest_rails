# frozen_string_literal: true

require 'rubydora'

class FedoraClient
  attr_reader :repository
  def initialize
    @repository = Rubydora.connect(
      url: Rails.application.secrets.fedora_url,
      user: Rails.application.secrets.fedora_username,
      password: Rails.application.secrets.fedora_password
    )
  end
  
  def mets_alto_for(uuid)
    require 'open-uri'
    this_url = "fedora/objects/uuid:#{uuid}/datastreams/METS_ALTO/content"
    begin
      string_io = open("http://repo.nypl.org:80/#{this_url}", http_basic_authentication: [Rails.application.secrets.fedora_username, Rails.application.secrets.fedora_password])
      mets_alto_doc = Nokogiri::XML(string_io)
      mets_alto_doc.remove_namespaces!
      mets_alto = mets_alto_doc.to_xml.to_s.gsub("<?xml version=\"1.0\" standalone=\"no\"?>\n","").gsub(' schemaLocation="http://schema.ccs-gmbh.com/ALTO alto.xsd"','').gsub("\n","").gsub("\t","")
      mets_alto
    end
  end
end
