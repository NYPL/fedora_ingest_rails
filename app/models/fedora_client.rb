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
  
  # Mapping old java attributes to variables. 
  # String id,     String dsid, String content, String label,             String controlGroup, String dsLocation, String checksum, String checkSumType, String mimeType, List<String> altIDs
  # "uuid:"+id[1], label,       null,           label+" for this object", "E",                "http://local.fedora.server/resolver/"+fileUUID, checkSum,"MD5",mimeType, permalinks
  # 
  def add_image_filestore_entry_datastreams(filestore_entries, pid)
    filestore_entries.each do |f|
      file_uuid   = f.uuid
      file_label  = f.get_type(f.type)
      checksum    = f.checksum
      file_name   = f.file_name
      extension   = file_name.split('.')[-1]
      mime_type   = f.get_mimetype(extension)
      permalinks  = []
      # KK TODO: add permalink to master image to permalinks / altIds
      # Legacy related java code 
      #     if(label.equals("MASTER_IMAGE") && releaseMaster){
      #       String permalink = getPermalink("http://repo.nypl.org/fedora/objects/uuid:"+id[1]+"/datastreams/MASTER_IMAGE/content");
      #       permalinks.add(permalink);
      #     }
      if file_label != 'Unknown'
        require 'pry'; binding.pry;
        puts "Creating datastream for #{pid}, dsid: #{file_label}"
        self.repository.add_datastream(pid: pid, dsid: file_label, content: nil, controlGroup: 'E', mimeType: mime_type, dsLocation: 'http://local.fedora.server/resolver/'+file_uuid, checksumType: 'MD5', checksum: checksum, dsLabel: file_label + ' for this object', altIds: permalinks )
      end
      
    end
  end
end
