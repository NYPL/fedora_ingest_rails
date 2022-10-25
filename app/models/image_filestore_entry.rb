# frozen_string_literal: true

# This class talks to the MySQL database that stores the images that are in isilon.
class ImageFilestoreEntry < ActiveRecord::Base
  establish_connection(:image_filestore)
  self.table_name = 'file_store'

  # This DB's columns have capital letters.
  # ActiveRecord dislikes that. This maps it to downcased.
  columns = %w[id file_name checksum file_id time_stamp type w h status src iid uuid cdate size quar]
  columns.each { |column| alias_attribute(column.to_sym, column.upcase.to_sym) }

  def readonly?
    true
  end

  def types_dictionary
    { 'j' => 'JP2',
      'r' => 'REFERENCE_THUMBNAIL',
      't' => 'THUMBNAIL',
      'u' => 'MASTER_IMAGE',
      'w' => 'WIDE_THUMBNAIL',
      'd' => 'MR_SID',
      'x' => 'METS_ALTO',
      'q' => '_1600_PX',
      'v' => '_2560_PX',
      'g' => 'FULL_SIZE_JPEG' }
  end

  def mimetypes_dictionary
    { 'tif' => 'image/tiff',
      'gif' => 'image/gif',
      'jpg' => 'image/jpg',
      'pdf' => 'application/pdf',
      'xml' => 'text/xml',
      'jp2' => 'image/jp2',
      'wav' => 'audio/wav',
      'sid' => 'image/x-mrsid',
      'unknown' => 'application/octet-stream' }
  end

  def get_type(string)
    types_dictionary[string] || 'Unknown'
  end

  def get_mimetype(string)
    mimetypes_dictionary[string] || mimetypes_dictionary['unknown']
  end

  def self.has_file?(file_id)
    where(file_id: file_id).present?
  end
end
