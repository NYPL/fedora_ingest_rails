# frozen_string_literal: true

class S3Client
  def initialize
    Aws::S3::Client.new(
      region: (ENV['AWS_REGION'] || 'us-east-1'),
      access_key_id: ENV['AWS_ACCESS_KEY_ID'],
      secret_access_key: ENV['AWS_SECRET_ACCESS_KEY']
    )
  end

  def mets_alto_for(uuid)
    begin
      response = @s3.get_object(bucket: ENV['S3_BUCKET_NAME'], key: "mets_altos/#{uuid}.xml")
      raw_xml = response&.body&.read
    rescue Exception => e
      puts "mets alto could not be retrieved for uuid: #{uuid} because #{e}"
    end

    return nil unless raw_xml

    mets_alto_doc = Nokogiri::XML(raw_xml)
    mets_alto_doc.remove_namespaces!
    mets_alto = mets_alto_doc.to_xml
                             .to_s
                             .squish # remove extra whitespace
                             .gsub("<?xml version=\"1.0\" standalone=\"no\"?>\n", '')
                             .gsub(' schemaLocation="http://schema.ccs-gmbh.com/ALTO alto.xsd"','')
                             .gsub('> <','><') # remove single whitespaces between xml tags
                             .gsub("\n",'')
                             .gsub("\t",'')
    mets_alto
  end
end
