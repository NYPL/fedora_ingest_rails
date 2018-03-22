# This class talks to the MySQL database that stores the images that are in isilon.
class AmiFilestoreEntry < ActiveRecord::Base
  self.establish_connection("#{Rails.env}_ami_filestore".to_sym)
  self.table_name = "assets"
end
