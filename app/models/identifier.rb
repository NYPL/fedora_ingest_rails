# frozen_string_literal: true

# This class talks to the MySQL database that stores the images that are in isilon.
class Identifier < ActiveRecord::Base
  belongs_to :identifiable, polymorphic: true

  establish_connection(:ami_filestore)
  self.table_name = 'identifiers'
end
