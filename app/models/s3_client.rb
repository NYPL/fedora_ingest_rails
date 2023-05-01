# frozen_string_literal: true

class S3Client
  def initialize
    @s3 ||= Aws::S3::Client.new
  end

  def mets_alto_for(uuid)
    begin
      response = @s3.get_object(bucket: ENV['S3_BUCKET_NAME'], key: "mets_altos/#{uuid}.xml")
      raw_xml = response&.body&.read
    rescue Exception => e
      logger.warn "mets alto could not be retrieved for uuid: #{uuid} because #{e}"
    end

    return nil unless raw_xml

    mets_alto_doc = Nokogiri::XML(raw_xml)
    mets_alto_doc.remove_namespaces!
    mets_alto = mets_alto_doc.to_xml
                             .to_s
                             .gsub("<?xml version=\"1.0\" standalone=\"no\"?>\n", '')
                             .gsub(' schemaLocation="http://schema.ccs-gmbh.com/ALTO alto.xsd"','')
                             .gsub("\n",'')
                             .gsub("\t",'')
    mets_alto
  end
end
