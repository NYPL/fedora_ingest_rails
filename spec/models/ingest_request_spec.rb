# frozen_string_literal: true

require 'rails_helper'

RSpec.describe IngestRequest, type: :model do
  describe 'scopes' do
    it "'ingested' returns IngestRequests with non-null ingested_at timestamps" do
      ingest_request = create(:ingest_request, ingested_at: Time.now.utc)
      expect(IngestRequest.ingested.all).to include(ingest_request)
    end

    it "'pending_ingest' returns IngestRequests with null ingested_at timestamps" do
      ingest_request = create(:ingest_request, ingested_at: nil)
      expect(IngestRequest.pending_ingest.all).to include(ingest_request)
    end
  end

  describe 'validations' do
    it { is_expected.to validate_presence_of(:uuid) }

    it 'will not allow two pending_ingest records with the same UUID' do
      first_request  = create(:ingest_request, uuid: '1234', ingested_at: nil)
      second_request = build(:ingest_request, uuid: '1234',  ingested_at: nil)
      expect(second_request).not_to be_valid
      expect(second_request.errors[:uuid]).to include('is already pending ingest')
    end

    it 'allows a second record, with the same uuid if the previous record(s) are ingested' do
      first_request  = create(:ingest_request, uuid: '1234', ingested_at: Time.now.utc)
      second_request = build(:ingest_request, uuid: '1234',  ingested_at: nil)
      expect(second_request).to be_valid
    end
  end
end
