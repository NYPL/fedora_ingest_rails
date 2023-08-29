# frozen_string_literal: true

require 'rails_helper'

RSpec.describe RepoSolrClient, type: :model do
  
  describe 'RepoSolrClient' do
    let(:solr_mock) { double('SolrInstance') }
    subject { RepoSolrClient.new }

    before(:each) do
      allow(Rails).to receive_message_chain(:application, :secrets, :repo_solr_url).and_return('http://fake.com/solr')
    end
    
    describe 'update index' do
      it 'removes the parent document if the parent will be empty once this is updated' do
        # Configure mock behavior
        allow(solr_mock).to receive(:get).with('select', params: { q: 'uuid:uuid1' } ).and_return('response' => {'docs' => [{'uuid' => 'uuid1', 'parentUUID' => ['old_uuid1']}]})
        allow(solr_mock).to receive(:get).with('select', params: { q: "parentUUID:\"old_uuid1\" AND type_s:Item" } ).and_return('response' => {'docs' => [{'uuid' => 'uuid1', 'parentUUID' => ['old_uuid1']}], 'numFound' => 1 })
        allow(solr_mock).to receive(:delete_by_query)
        allow(solr_mock).to receive(:add)
        allow(solr_mock).to receive(:commit)

        # Use the mock in the RepoSolrClient instance
        allow(RSolr).to receive(:connect).and_return(solr_mock)

        # Create a new document with updated parentUUIDs
        new_document = { uuid: 'uuid1', parentUUID: ['new_parent_uuid1'] }
        subject.update_index_and_delete_empty_parents(new_document)

        # Verify mock interactions
        expect(solr_mock).to have_received(:get).with('select', params: { q: "parentUUID:\"old_uuid1\" AND type_s:Item" } )
        expect(solr_mock).to have_received(:delete_by_query).with('uuid:old_uuid1')
        expect(solr_mock).to have_received(:add).with([new_document])
        expect(solr_mock).to have_received(:commit)
      end
      
      it 'does not remove the parent document if the parent will not be empty once this is updated' do
        allow(solr_mock).to receive(:get).with('select', params: { q: 'uuid:uuid10' } ).and_return('response' => {'docs' => [{'uuid' => 'uuid10', 'parentUUID' => ['old_populated_uuid1']}]})
        allow(solr_mock).to receive(:get).with('select', params: { q: "parentUUID:\"old_populated_uuid1\" AND type_s:Item" } ).and_return('response' => {'docs' => [{'uuid' => 'uuid10', 'parentUUID' => ['old_populated_uuid1']}, {'uuid' => 'uuid11', 'parentUUID' => ['old_populated_uuid1']}], 'numFound' => 2 })
        allow(solr_mock).to receive(:delete_by_query)
        allow(solr_mock).to receive(:add)
        allow(solr_mock).to receive(:commit)

        # Use the mock in the RepoSolrClient instance
        allow(RSolr).to receive(:connect).and_return(solr_mock)
        
        # Create a new document with updated parentUUIDs
        second_new_document = { uuid: 'uuid10', parentUUID: ['new_parent_uuid1'] }
        subject.update_index_and_delete_empty_parents(second_new_document)

        # Verify mock interactions
        expect(solr_mock).to have_received(:get).with('select', params: { q: "parentUUID:\"old_populated_uuid1\" AND type_s:Item" } )
        expect(solr_mock).to_not have_received(:delete_by_query).with('uuid:old_populated_uuid1')
        expect(solr_mock).to have_received(:add).with([second_new_document])
        expect(solr_mock).to have_received(:commit)
      end
    end
  end
end
