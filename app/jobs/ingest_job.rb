# frozen_string_literal: true

Rubydora.logger = NyplLogFormatter.new(STDOUT)

IngestJob = Struct.new(:ingest_request_id, :test_mode) do
  include IngestJobHelper

  def perform
    ingest_request = IngestRequest.where(id: ingest_request_id).first
    if ingest_request
      ingest!(ingest_request, test_mode)
      ingest_request.update_attributes(ingested_at: Time.now.utc)
    end
  end
end
