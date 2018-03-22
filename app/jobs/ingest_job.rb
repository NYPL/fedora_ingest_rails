IngestJob = Struct.new(:ingest_request_id) do
  def perform
    @ingest_request = IngestRequest.where(id: ingest_request_id).first
    if @ingest_request
      self.ingest!
      @ingest_request.update_attributes(ingested_at: Time.now.utc)
    end
  end

  def ingest!
    fedora_client = FedoraClient.new

    # Fetch stuff from MMS
    mods   = MMSClient.new.mods_for(@ingest_request.uuid)
    rights = MMSClient.new.rights_for(@ingest_request.uuid)

    pid = "uuid:#{@ingest_request.uuid}"
    digital_object = fedora_client.repository.find_or_initialize(pid)
    # We can check digital_object.new? here.
    digital_object.label = "This object's title - we'll grab it from MMS"
    digital_object.save
    ##  For some reason this can only be done on saved objects
    digital_object.models << 'info:fedora/nypl-model:image'

    # TODO:
    #  * This should be a add-or creation of the datastream
    #  * Figure "Datastream Location Type", and MD5 Checksuming
    #  * React to MMS giving a sucsessful response (Should probably be a feature of MMSClient)
    fedora_client.repository.add_datastream(pid: pid, dsid: "MODSXML", content: mods, content_type: "text/xml", dsChecksumType: "MD5", dsLocationType: 'INTERNAL_ID', dsLabel: "MODS XML record for this object")
    fedora_client.repository.add_datastream(pid: pid, dsid: "RIGHTS",  content: rights, content_type: "text/xml", dsChecksumType: "MD5", dsLocationType: 'INTERNAL_ID', dsLabel: "Rights XML record for this object")
    digital_object.save
    Delayed::Worker.logger.debug({uuid: pid, message: "done ingesting"}.to_json)
  end
end
