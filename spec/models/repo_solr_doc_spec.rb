# spec/models/repo_solr_doc_spec.rb

require 'rails_helper'

RSpec.describe RepoSolrDoc, type: :model do
  describe 'validations' do
    it { should validate_presence_of(:uuid) }
  end

  describe 'class methods' do
    let(:current_time) { Time.current }

    describe '.get_datetime_s' do
      it 'returns the current time formatted as Solr date string' do
        allow(Time).to receive(:current).and_return(current_time)
        formatted_date = RepoSolrDoc.get_datetime_s
        expected_format = current_time.iso8601(3)

        expect(formatted_date).to eq(expected_format)
      end
    end

    describe '.get_datetime_dt' do
      it 'returns the current time formatted as Solr date-time string' do
        allow(Time).to receive(:current).and_return(current_time)
        formatted_date_time = RepoSolrDoc.get_datetime_dt
        expected_format = current_time.strftime('%Y-%m-%dT%H:%M:%SZ')

        expect(formatted_date_time).to eq(expected_format)
      end
    end

    describe '.format_as_solr_s' do
      it 'formats the datetime as Solr date string' do
        datetime = Time.current
        formatted_date = RepoSolrDoc.format_as_solr_s(datetime)
        expected_format = datetime.iso8601(3)

        expect(formatted_date).to eq(expected_format)
      end
    end

    describe '.format_as_solr_dt' do
      it 'formats the datetime as Solr date-time string' do
        datetime = Time.current
        formatted_date_time = RepoSolrDoc.format_as_solr_dt(datetime)
        expected_format = datetime.strftime('%Y-%m-%dT%H:%M:%SZ')

        expect(formatted_date_time).to eq(expected_format)
      end
    end
  end
end
