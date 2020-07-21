# frozen_string_literal: true

require 'rails_helper'

RSpec.describe RepoSolrClient, type: :model do
  before do
    @repo_solr_client = RepoSolrClient.new(mms_url: 'http://example.com', user_name: 'The Log-in Lady', password: 'stephenX3')
  end
  
  describe 'makes basic requests' do
    it 'makes a request to get solr doc' do
      expect(HTTP).to_not receive(:get).with('http://example.com/exports/mods/abc-123', params: {}) { double(code: 200) }
      @repo_solr_client.get_doc('uuid-8675309')
    end
    
    it 'does not run real solr requests in test mode' do
      expect(@repo_solr_client.get_doc('uuid-8675309')).to eq(nil)
    end
  end
end