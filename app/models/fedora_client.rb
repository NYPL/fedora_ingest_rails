require 'rubydora'

class FedoraClient
  attr_reader :repository
  def initialize
    @repository = Rubydora.connect(
      url:      Rails.application.secrets.fedora_url,
      user:     Rails.application.secrets.fedora_username,
      password: Rails.application.secrets.fedora_password
    )
  end
  
  def add_image_filestore_entry_datastreams(filestore_entries, pid)
    filestore_entries.each do |f|
      # self.repository.add_datastream(pid: pid, dsid: 'DC',      content: dublin_core, formatURI: 'http://www.openarchives.org/OAI/2.0/oai_dc/', content_type: 'text/xml', checksumType: 'MD5', dsLabel: 'DC XML record for this object')
      puts f.uuid
    end
  end
end
