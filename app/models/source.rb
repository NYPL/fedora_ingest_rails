# This class talks to the MySQL database that stores the images that are in isilon.
class Source < ActiveRecord::Base
  establish_connection(:ami_filestore)
  self.table_name = 'sources'

  def readonly?
    !Rails.env.test?
  end
end
