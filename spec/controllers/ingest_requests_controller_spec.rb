require 'rails_helper'

RSpec.describe IngestRequestsController, type: :controller do
  it "will call create on UUID sent to it" do
    uuids = ['1','2','3','4','5']
    uuids.each do |uuid|
      expect(IngestRequest).to receive(:create).with({uuid: uuid})
    end
    post :create, params: {uuids: uuids}, format: :json
  end

  it "won't try to create duplicate UUIDs" do
    IngestRequest.destroy_all
    uuids = ['1','1','2']
    expect(IngestRequest).to receive(:create).with({uuid: '2'}).exactly(1).times
    expect(IngestRequest).to receive(:create).with({uuid: '1'}).exactly(1).times
    post :create, params: {uuids: uuids}, format: :json
  end

  it "won't try to to create a record if there's already a pending" do
    pending_request = create(:ingest_request, uuid: 'abc-123')
    expect(IngestRequest.count).to eq(1)
    uuids = [pending_request.uuid, '3', '4', '5']
    post :create, params: {uuids: uuids}, format: :json
    expect(IngestRequest.count).to eq(4)
  end

  it "returns a 201" do
    post :create, params: {uuids: [1,2,3]}, format: :json
    expect(response.status).to eq(201)
  end
end
