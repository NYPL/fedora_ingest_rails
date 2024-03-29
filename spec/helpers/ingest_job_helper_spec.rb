require 'rails_helper'

RSpec.describe 'IngestHelper', type: :helper do
  describe '#ingest!' do
    subject { helper.ingest!(ingest_request) }

    let(:ingest_request) { create(:ingest_request) }

    let(:mock_logger) { double('logger', :info => true) }
    let(:mock_fedora_client) { double('fedora_client', :repository => repository) }

    let(:repository) {
      double('repository',
        :find_or_initialize => digital_object,
        :add_datastream => true
      )
    }

    let(:digital_object) {
      double('digital_object',
        'label=' => true,
        :save => true,
        :models => []
      )
    }

    let(:mock_mms_client) {
      double('mms_client',
        :mods_for => mods,
        :dublin_core_for => dublin_core,
        :repo_docs_for => repo_docs,
        :captures_for_item => captures,
        :rights_for => rights,
        :rels_ext_for => rels_ext,
        :repo_doc_for => true,
        :full_rels_ext_solr_docs_for => rels_ext_solr_docs
      )
    }

    let(:mods) { 'some_mods' }
    let(:dublin_core) { 'some_dublin_core' }
    let(:repo_docs) { [repo_doc_1, repo_doc_2] }
    let(:repo_doc_1) { { 'uuid' => 'repo_doc_1_uuid' } }
    let(:repo_doc_2) { { 'uuid' => 'repo_doc_2_uuid' } }
    let(:captures) { [capture_1, capture_2] }
    let(:capture_1) { { :uuid => 'capture_1_uuid' } }
    let(:capture_2) { { :uuid => 'capture_2_uuid' } }
    let(:indexed_uuids) { [repo_doc_1['uuid'], repo_doc_2['uuid'], capture_1[:uuid], capture_2[:uuid]] }
    let(:rights) { "<nyplRights></nyplRights>" }
    let(:rels_ext) { 'some_rels_ext' }
    let(:rels_ext_solr_docs) { 'some_rels_ext_solr_docs' }
    let(:image_filestore_entry) { ImageFilestoreEntry.new(
      file_name: 'filename.tif',
      uuid: 'uuid',
      type: 'u'
    )}
    let(:mock_permalink) { 'http://example.com/master.tif' }
    let(:mock_repo_solr_client) {
      double('repo_solr_client',
        :add_docs_to_solr => true,
        :commit_index_changes => true
      )
    }

    before do
      allow(Delayed::Worker).to receive(:logger).and_return(mock_logger)
      allow(FedoraClient).to receive(:new).and_return(mock_fedora_client)
      allow(MMSClient).to receive(:new).and_return(mock_mms_client)
      allow(RepoSolrClient).to receive(:new).and_return(mock_repo_solr_client)
      allow(mock_repo_solr_client).to receive(:delete_unseen_captures_below).with("MyString", ["capture_1_uuid", "capture_2_uuid"])
      allow(mock_mms_client).to receive(:repo_doc_for).with(capture_1[:uuid]).and_return(capture_1).once
      allow(mock_mms_client).to receive(:repo_doc_for).with(capture_2[:uuid]).and_return(capture_2).once
      allow(ImageFilestoreEntry).to receive(:where).and_return([image_filestore_entry])
      allow_any_instance_of(PermalinkClient).to receive(:fetch_or_mint_permalink).and_return(mock_permalink)
    end

    context 'high res links' do
      context 'when the rights statement has no uses specified' do
        let(:rights) { "<nyplRights></nyplRights>" }

        it 'should have no highResLink value' do
          expect(mock_repo_solr_client).to receive(:add_docs_to_solr).with(hash_including({
            :uuid => capture_1[:uuid],
            'highResLink' => nil
          })).once
          subject
        end
      end

      context 'when the rights statement specifies releasing the high res master' do
        let(:rights) {
          <<-XML
          <nyplRights>
            <useStatement>
              <use>#{IngestJobHelper::RELEASE_MASTER_OK}</use>
            </useStatement>
          </nyplRights>
          XML
        }

        it 'should have a highResLink value' do
          expect(mock_repo_solr_client).to receive(:add_docs_to_solr).with(hash_including({
            :uuid => capture_1[:uuid],
            'highResLink' => mock_permalink
          })).once
          subject
        end
      end

      context 'when the rights statement specifies a public domain code' do
        let(:rights) {
          <<-XML
          <nyplRights>
            <useStatement>
              <use>#{IngestJobHelper::PUBLIC_DOMAIN_RIGHTS_CODES.first}</use>
            </useStatement>
          </nyplRights>
          XML
        }

        it 'should have a highResLink value' do
          expect(mock_repo_solr_client).to receive(:add_docs_to_solr).with(hash_including({
            :uuid => capture_1[:uuid],
            'highResLink' => mock_permalink
          })).once
          subject
        end
      end
    end

    context 'a repo doc uuid is in the oral history collection' do
      let(:repo_doc_1) { { 'uuid' => 'da4687f0-cc71-0130-fb40-58d385a7b928' } }
      let(:mock_s3_client) { double('s3_client', :mets_alto_for => mets_alto) }
      let(:mets_alto) { "<?xml version=\"1.0\"?><alto><String CONTENT=\"ADrLPH\" ID=\"St_1.1.1.3\" HPOS=\"2536\" VPOS=\"1400\" HEIGHT=\"140\" WIDTH=\"700\" STYLEREFS=\"Style_1\" WC=\"7.3\" CC=\"007000\"/></alto>" }

      let(:parent_or_item_repo_solr_doc_1_partial) { { 'uuid' => repo_doc_1['uuid'] } }
      let(:parent_or_item_repo_solr_doc_2_partial) { { 'uuid' => repo_doc_2['uuid'] } }
      let(:expected_capture_solr_doc_1_partial) {
        {
          'captureText_ocrtext' => 'ADrLPH',
          'hasOCR' => true,
          'mets_alto' => mets_alto,
          :uuid => capture_1[:uuid]
        }
      }
      let(:expected_capture_solr_doc_2_partial) {
        {
          'captureText_ocrtext' => 'ADrLPH',
          'hasOCR' => true,
          'mets_alto' => mets_alto,
          :uuid => capture_2[:uuid]
        }
      }

      before { allow(S3Client).to receive(:new).and_return(mock_s3_client) }

      it 'adds ocr text, has ocr, and mets alto to the docs' do
        expect(mock_repo_solr_client).to receive(:add_docs_to_solr).with(array_including(hash_including(parent_or_item_repo_solr_doc_1_partial), hash_including(parent_or_item_repo_solr_doc_2_partial)), true).once
        expect(mock_repo_solr_client).to receive(:add_docs_to_solr).with(hash_including(expected_capture_solr_doc_1_partial)).once
        expect(mock_repo_solr_client).to receive(:add_docs_to_solr).with(hash_including(expected_capture_solr_doc_2_partial)).once
        subject
      end
    end

    context 'the indexing time is known' do
      before { allow(Time).to receive(:now).and_return(Time.parse(known_datetime)) }

      let(:known_datetime) { "2024-02-12 14:06:10 +0000" }
      let(:expected_utc_timestamp) { Time.parse(known_datetime).utc.strftime('%Y-%m-%dT%H:%M:%S.%LZ') }
      let(:expected_dt_timestamp) { Time.parse(known_datetime).strftime('%Y-%m-%dT%H:%M:%SZ') }

      let(:expected_parent_and_item_repo_solr_docs) { [parent_or_item_repo_solr_doc_1, parent_or_item_repo_solr_doc_2] }
      let(:parent_or_item_repo_solr_doc_1) {
        {
          'firstIndexed_s' => expected_utc_timestamp,
          'firstIndexed_dt' => expected_dt_timestamp,
          'dateIndexed_s' => expected_utc_timestamp,
          'dateIndexed_dt' => expected_dt_timestamp,
          'uuid' => repo_doc_1['uuid']
        }
      }
      let(:parent_or_item_repo_solr_doc_2) {
        {
          'firstIndexed_s' => expected_utc_timestamp,
          'firstIndexed_dt' => expected_dt_timestamp,
          'dateIndexed_s' => expected_utc_timestamp,
          'dateIndexed_dt' => expected_dt_timestamp,
          'uuid' => repo_doc_2['uuid']
        }
      }

      let(:expected_capture_solr_doc_1) {
        {
          'firstIndexed_s' => expected_utc_timestamp,
          'firstIndexed_dt' => expected_dt_timestamp,
          'dateIndexed_s' => expected_utc_timestamp,
          'dateIndexed_dt' => expected_dt_timestamp,
          'highResLink' => nil,
          :uuid => capture_1[:uuid]
        }
      }
      let(:expected_capture_solr_doc_2) {
        {
          'firstIndexed_s' => expected_utc_timestamp,
          'firstIndexed_dt' => expected_dt_timestamp,
          'dateIndexed_s' => expected_utc_timestamp,
          'dateIndexed_dt' => expected_dt_timestamp,
          'highResLink' => nil,
          :uuid => capture_2[:uuid]
        }
      }

      it 'adds firstIndexed_s and dateIndexed_s to all the repo solr docs' do
        expect(mock_repo_solr_client).to receive(:add_docs_to_solr).with(expected_parent_and_item_repo_solr_docs, true).once
        expect(mock_repo_solr_client).to receive(:add_docs_to_solr).with(expected_capture_solr_doc_1).once
        expect(mock_repo_solr_client).to receive(:add_docs_to_solr).with(expected_capture_solr_doc_2).once
        subject
      end
    end

    context 'none of the repo solr docs exist' do
      it 'creates the parent and item repo solr docs and sets their first indexed values' do
        subject
        from_db_1 = RepoSolrDoc.find_by(uuid: repo_doc_1['uuid'])
        from_db_2 = RepoSolrDoc.find_by(uuid: repo_doc_2['uuid'])
        expect(from_db_1).not_to be_nil
        expect(from_db_2).not_to be_nil
        expect(from_db_1.first_indexed).not_to be_nil
        expect(from_db_2.first_indexed).not_to be_nil
      end

      it 'creates the capture repo solr docs and sets their first indexed values' do
        subject
        from_db_1 = RepoSolrDoc.find_by(uuid: capture_1[:uuid])
        from_db_2 = RepoSolrDoc.find_by(uuid: capture_2[:uuid])
        expect(from_db_1).not_to be_nil
        expect(from_db_2).not_to be_nil
        expect(from_db_1.first_indexed).not_to be_nil
        expect(from_db_2.first_indexed).not_to be_nil
      end
    end

    context 'all of the repo solr docs exist' do
      context 'and all of them have first indexed values' do
        before do
          first_indexed_time = Time.now - 3.days
          indexed_uuids.each { |uuid| RepoSolrDoc.create!(uuid: uuid, first_indexed: first_indexed_time) }
        end

        it 'does not update their first indexed values' do
          expected_first_indexed_time = RepoSolrDoc.first.first_indexed
          subject
          RepoSolrDoc.all.each { |doc| expect(doc.first_indexed).to eq(expected_first_indexed_time) }
        end
      end

      context 'and none of them have first indexed values' do
        before { indexed_uuids.each { |uuid| RepoSolrDoc.create!(uuid: uuid) } }

        it 'updates their first indexed values' do
          expected_first_indexed_time = RepoSolrDoc.first.first_indexed
          subject
          RepoSolrDoc.all.each { |doc| expect(doc.first_indexed).not_to be_nil }
        end
      end
    end
  end
end
