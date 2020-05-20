# frozen_string_literal: true

# This class talks to the MySQL database that stores the images that are in isilon.
class AmiFilestoreEntry < ActiveRecord::Base
  establish_connection(:ami_filestore)
  self.table_name = 'assets'

  belongs_to :source

  def readonly?
    true
  end
end
