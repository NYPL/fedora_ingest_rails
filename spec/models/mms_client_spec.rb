require 'rails_helper'

RSpec.describe MMSClient, type: :model do
  before do
    @mms_client = MMSClient.new(mms_url: 'http://example.com', user_name: 'Kenny Logs-in', password: 'jobinX3')
  end

  it 'makes an HTTP Basic request to get MODS' do
    expect(HTTP).to receive(:basic_auth).with(user: 'Kenny Logs-in', pass: 'jobinX3') { HTTP }
    expect(HTTP).to receive(:get).with('http://example.com/exports/mods/abc-123') { HTTP }
    @mms_client.mods_for('abc-123')
  end

  it 'makes an HTTP Basic request to get RELS-EXT' do
    expect(HTTP).to receive(:basic_auth).with(user: 'Kenny Logs-in', pass: 'jobinX3') { HTTP }
    expect(HTTP).to receive(:get).with('http://example.com/exports/rels_ext/abc-123') { HTTP }
    @mms_client.rels_ext_for('abc-123')
  end

  it 'makes an HTTP Basic request to get Rights' do
    expect(HTTP).to receive(:basic_auth).with(user: 'Kenny Logs-in', pass: 'jobinX3') { HTTP }
    expect(HTTP).to receive(:get).with('http://example.com/exports/rights/abc-123') { HTTP }
    @mms_client.rights_for('abc-123')
  end

  it 'makes an HTTP Basic request to get Dublin Core' do
    expect(HTTP).to receive(:basic_auth).with(user: 'Kenny Logs-in', pass: 'jobinX3') { HTTP }
    expect(HTTP).to receive(:get).with('http://example.com/exports/dc/abc-123') { HTTP }
    @mms_client.dublin_core_for('abc-123')
  end
end
