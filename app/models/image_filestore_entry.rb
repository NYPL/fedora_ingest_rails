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
end
