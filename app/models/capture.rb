# frozen_string_literal: true

# This class talks to the MySQL database that stores the images that are in isilon.
class Capture < ActiveRecord::Base
  has_many :identifiers, as: :identifiable

  establish_connection(:ami_filestore)
  self.table_name = 'captures'
end
