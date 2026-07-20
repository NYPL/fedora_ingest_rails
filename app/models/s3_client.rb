# frozen_string_literal: true

class S3Client
  def initialize
    @s3 ||= Aws::S3::Client.new(region: (ENV['AWS_REGION'] || 'us-east-1'), access_key_id: ENV['AWS_ACCESS_KEY_ID'], secret_access_key: ENV['AWS_SECRET_ACCESS_KEY'])
  end

  def ocr_for(uuid)
    begin
      response = @s3.get_object(bucket: ENV['S3_BUCKET_NAME'], key: "ocr/#{uuid}")
      raw_text = response&.body&.read
    rescue Exception => e
      puts "ocr could not be retrieved for uuid: #{uuid} because #{e}"
    end

    return nil unless raw_text

    if raw_text.include?("<alto>")
      mets_alto_doc = Nokogiri::XML(raw_text)
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

  def has_allmaps_data(uuid)
    # populate allmaps list if not available yet. store the list in an instance variable so that it can be reused for subsequent calls to this method.
    @allmaps_data ||= begin
      response = @s3.get_object(bucket: ENV['S3_BUCKET_NAME'], key: "allmaps_data/allmaps_captures.txt")
      raw_text = response&.body&.read
      raw_text.split("\n").map(&:strip)
    rescue Aws::S3::Errors::NotFound
      puts "unable to locate allmaps_captures.txt in S3"
      false
    end
    @allmaps_data.include?(uuid)
  end
end