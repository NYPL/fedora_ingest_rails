require 'rails_helper'

RSpec.describe RepoSolrClient, type: :model do
  let(:mock_rsolr) { double('RSolr') }
  let(:mms_client) { instance_double(MmsClient) }
  subject { RepoSolrClient.new }

  before do
    # Mock RSolr connection
    allow(RSolr).to receive(:connect).and_return(mock_rsolr)

    # Stub RSolr methods
    allow(mock_rsolr).to receive(:get).and_return({ "response" => { "docs" => [] } })
    allow(mock_rsolr).to receive(:update).and_return(nil)
    allow(mock_rsolr).to receive(:commit).and_return(nil)
    allow(mock_rsolr).to receive(:add).and_return(nil)

    # Stub the logger
    allow(Delayed::Worker.logger).to receive(:info)

    subject.instance_variable_set(:@rsolr, mock_rsolr)

    stub_const("RepoSolrClient::NYPL_LOCATIONS", ["Location1", "Location2"])
  end

  describe '#get_number_of_children_for_parent_uuid' do
    it 'returns the correct number of children' do
      allow(mock_rsolr).to receive(:get).with('select', params: { q: 'parentUUID:"parent1" AND type_s:Item', rows: 0 })
                                        .and_return({ "response" => { "numFound" => 5 } })

      result = subject.get_number_of_children_for_parent_uuid("parent1")
      expect(result).to eq(5)
    end

    it 'returns nil if @rsolr is not set' do
      subject.instance_variable_set(:@rsolr, nil)
      result = subject.get_number_of_children_for_parent_uuid("parent1")
      expect(result).to be_nil
    end
  end

  describe '#get_representative_children_for' do
    context 'when type is Item' do
      it 'returns up to two captures sorted by orderInSequence and imageID_string' do
        allow(mock_rsolr).to receive(:get).and_return({
          "response" => {
            "docs" => [
              { "uuid" => "child1", "orderInSequence" => 1, "imageID_string" => "image1" },
              { "uuid" => "child2", "orderInSequence" => 2, "imageID_string" => "image2" },
              { "uuid" => "child3", "orderInSequence" => 3, "imageID_string" => "image3" }
            ]
          }
        })

        result = subject.get_representative_children_for("parent1", "item")
        expect(result.size).to eq(3)
        expect(result.map { |doc| doc["uuid"] }).to eq(["child1", "child2", "child3"])
      end
    end
  end

  describe '#update_key_fields' do
    let(:solr_docs_array) do
      [
        { "uuid" => "item1", "type_s" => "http://uri.nypl.org/vocabulary/repository_terms#Item", "parentUUID" => ["parent1"], "typeOfResource_mtxt_s" => ["sound recording"] }
      ]
    end

    it 'updates Solr with processed fields' do
      allow(subject).to receive(:get_representative_children_for).and_return([
        { "uuid" => "capture1", "type_s" => "http://uri.nypl.org/vocabulary/repository_terms#Capture", "parentUUID" => ["item1"], "typeOfResource_mtxt_s" => ["sound recording"], "imageID_string" => "image1", "orderInSequence" => 1 }
      ])
      allow(subject).to receive(:get_number_of_children_for_parent_uuid).and_return(5)

      subject.update_key_fields(solr_docs_array)

      expect(mock_rsolr).to have_received(:update) do |args|
        updates = JSON.parse(args[:data])
        item_update = updates.find { |doc| doc["uuid"] == "item1" }

        expect(item_update["containsMultipleCaptures"]).to eq(false)
        expect(item_update["numItems_s"]).to eq(1)
        expect(item_update["containsAVMaterial"]).to eq(true)
        expect(item_update["containsOnSiteMaterial"]).to eq(false)
        expect(item_update["containsUnrestrictedMaterial"]).to eq(false)
        expect(item_update["imageID"]).to eq("image1")
      end
    end

    it 'skips updates for Capture documents' do
      subject.update_key_fields(solr_docs_array)
      expect(mock_rsolr).to have_received(:update) do |args|
        updates = JSON.parse(args[:data])
        expect(updates.none? { |doc| doc["uuid"] == "capture1" }).to be true
      end
    end
  end

  describe '#update_index_and_delete_empty_parents' do
    let(:new_document) { { "uuid" => "item1", "parentUUID" => ["new_parent1"] } }

    it 'deletes old parents with no children and updates remaining parents' do
      allow(subject).to receive(:get_doc).with("item1").and_return({ "docs" => [{ "uuid" => "item1", "parentUUID" => ["old_parent1"] }] })
      allow(subject).to receive(:get_doc).with("old_parent1").and_return({ "docs" => [{ "uuid" => "old_parent1" }] })
      allow(subject).to receive(:get_number_of_children_for_parent_uuid).with("old_parent1").and_return(0)
      allow(subject).to receive(:remove_doc_for).with("old_parent1")

      subject.update_index_and_delete_empty_parents(new_document)

      expect(subject).to have_received(:remove_doc_for).with("old_parent1")
      expect(mock_rsolr).to have_received(:add).with(new_document)
    end
  end

  describe '#update_key_fields_for_parent_uuids' do
    let(:uuids) { ['uuid-1', 'uuid-2'] }

    let(:solr_response) do
      {
        "response" => {
          "docs" => [
            { "uuid" => "uuid-1", "title" => "Parent 1" },
            { "uuid" => "uuid-2", "title" => "Parent 2" }
          ]
        }
      }
    end

    it 'sends the correct Solr query and calls update_key_fields with docs' do
      expected_fq = 'uuid:("uuid-1" "uuid-2")'

      expect(mock_rsolr).to receive(:get).with('select', params: {
        q: '*:*',
        fq: expected_fq,
        rows: 100
      }).and_return(solr_response)

      expect(subject).to receive(:update_key_fields).with(solr_response["response"]["docs"])

      subject.update_key_fields_for_parent_uuids(uuids)
    end

    it 'does not call update_key_fields if Solr returns no docs' do
      empty_response = { "response" => { "docs" => [] } }

      expect(mock_rsolr).to receive(:get).and_return(empty_response)
      expect(subject).to receive(:update_key_fields).with([])

      subject.update_key_fields_for_parent_uuids(uuids)
    end

    it 'does nothing if @rsolr is nil' do
      subject.instance_variable_set(:@rsolr, nil)
      expect(subject).not_to receive(:update_key_fields)

      subject.update_key_fields_for_parent_uuids(uuids)
    end
  end

  describe "#delete_unseen_captures_below" do
    it 'deletes an unseen capture with "No uses specified" and commits the delete' do
      # Arrange: Solr setup for one result, MMS setup for 'No uses'
      seen_uuids = ['capture-1']
      unseen_uuid = 'capture-2'
      solr_doc = { 'uuid' => unseen_uuid, 'imageID_string' => 'img-1' }

      # Stub initial query (rows: 0)
      allow(mock_rsolr).to receive(:get).with('select', params: hash_including(rows: 0)).and_return(
        'response' => { 'numFound' => 1 }
      )

      # Stub paged query (page 0)
      allow(mock_rsolr).to receive(:get).with('select', params: hash_including(start: 0, rows: 250)).and_return(
        'response' => { 'docs' => [solr_doc] }
      )

      # Stub MMS response
      allow(mms_client).to receive(:rights_for).with(unseen_uuid).and_return(["No uses specified."])

      # Stub delete and commit
      expect(mock_rsolr).to receive(:delete_by_id).with(unseen_uuid)
      expect(mock_rsolr).to receive(:commit)

      subject.delete_unseen_captures_below('item-1', seen_uuids, mms_client)
    end
  end
end
