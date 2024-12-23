# frozen_string_literal: true

class LinkStore < ActiveRecord::Base
  establish_connection(:image_filestore)
  self.table_name = 'link_store'

  def uuid
    if self.url =~ /uuid:([a-f0-9\-]+)/
      uuid = $1
      #puts "Extracted UUID: #{uuid}"
    else
      uuid = nil
      #puts "No UUID found in the URL"
    end

    uuid
  end

end
