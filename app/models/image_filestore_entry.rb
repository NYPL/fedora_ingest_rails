# This class talks to the MySQL database that stores the images that are in isilon.
class ImageFilestoreEntry < ActiveRecord::Base
  self..establish_connection("#{Rails.env}_image_filestore".to_sym)
  self.table_name = "file_store"
end
