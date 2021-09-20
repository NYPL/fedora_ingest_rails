# frozen_string_literal: true

require 'rails_helper'

RSpec.describe MMSClient, type: :model do
  before do
    @mms_client = MMSClient.new(mms_url: 'http://example.com', user_name: 'Kenny Logs-in', password: 'jobinX3')
  end

  describe 'HTTP Basic authenticated requests' do
    before :each do
      expect(HTTP).to receive(:basic_auth).with(user: 'Kenny Logs-in', pass: 'jobinX3') { HTTP }
    end

    it 'makes a request to get MODS' do
      expect(HTTP).to receive(:get).with('http://example.com/exports/mods/abc-123', params: {}) { double(code: 200) }
      @mms_client.mods_for('abc-123')
    end

    it 'makes a request to get RELS-EXT' do
      expect(HTTP).to receive(:get).with('http://example.com/exports/rels_ext/abc-123', params: {}) { double(code: 200) }
      @mms_client.rels_ext_for('abc-123')
    end

    it "makes a request to get the all ancestors' rels_exts" do
      expect(HTTP).to receive(:get).with('http://example.com/exports/full_rels_ext_solr_docs/abc-123', params: {}) { double(code: 200) }
      @mms_client.full_rels_ext_solr_docs_for('abc-123')
    end

    it 'makes a request to get Rights' do
      expect(HTTP).to receive(:get).with('http://example.com/exports/rights/abc-123', params: {}) { double(code: 200) }
      @mms_client.rights_for('abc-123')
    end

    it 'makes a request to get Dublin Core' do
      expect(HTTP).to receive(:get).with('http://example.com/exports/dc/abc-123', params: {}) { double(code: 200) }
      @mms_client.dublin_core_for('abc-123')
    end

    it "makes a request to get an Item's Captures" do
      expect(HTTP).to receive(:get).with('http://example.com/exports/get_captures/abc-123', params: { showAll: 'true' }) { double(code: 200) }
      @mms_client.captures_for_item('abc-123')
    end

    it 'Throws exceptions on bad requests' do
      expect(HTTP).to receive(:get).with('http://example.com/exports/dc/abc-123', params: {}) { double(code: 500) }
      expect { @mms_client.dublin_core_for('abc-123') }.to raise_error(Exception)
    end
  end
  
  describe 'json parsing' do
    it 'removes fields we do not want from solr docs, keeps those we do, and makes erroneous arrays single-value' do
      test_string = "[{\"uuid\":\"8fcbf960-fed9-0130-73f0-58d385a7bbd0\",\"firstInSequence\":[\"8fcbf960-fed9-0130-73f0-58d385a7bbd0\"],\"immediateParent_s\":\"81fffac0-cc75-0130-40e2-58d385a7b928\",\"mainTitle_sort\":\"get rid of this title\"}]"
      expect { @mms_client.convert_to_json_docs(test_string) }.to eq([{"uuid"=>"8fcbf960-fed9-0130-73f0-58d385a7bbd0", "firstInSequence"=>"8fcbf960-fed9-0130-73f0-58d385a7bbd0", "immediateParent_s"=>"81fffac0-cc75-0130-40e2-58d385a7b928"}])
    end
  end
end
