# frozen_string_literal: true

require 'rails_helper'

RSpec.describe S3Client, type: :model do
  before { allow(Aws::S3::Client).to receive(:new).and_return(mock_aws_s3_client) }
  let(:mock_aws_s3_client) { double('aws_s3_client', :get_object => mock_aws_s3_response) }

  describe '#mets_alto_for' do
    subject { S3Client.new.mets_alto_for(uuid) }
    let(:uuid) { 'some_uuid' }

    context 'the mets alto gets returned' do
      let(:mock_aws_s3_response) { double('aws_s3_response', :body => mock_aws_s3_response_body) }
      let(:mock_aws_s3_response_body) { double('aws_s3_response_body', :read => mets_alto) }
      let(:mets_alto) { "<?xml version=\"1.0\"?><alto><String CONTENT=\"ADrLPH\" ID=\"St_1.1.1.3\" HPOS=\"2536\" VPOS=\"1400\" HEIGHT=\"140\" WIDTH=\"700\" STYLEREFS=\"Style_1\" WC=\"7.3\" CC=\"007000\"/></alto>" }
      let(:expected_return_value) { '<?xml version="1.0"?><alto><String CONTENT="ADrLPH" ID="St_1.1.1.3" HPOS="2536" VPOS="1400" HEIGHT="140" WIDTH="700" STYLEREFS="Style_1" WC="7.3" CC="007000"/></alto>' }

      it 'returns the expected unescaped mets alto string' do
        expect(subject).to eq(expected_return_value)
      end
    end

    context 'the S3 response cannot be parsed as expected' do
      let(:mock_aws_s3_response) { 'some_unexpected_response' }

      it 'returns nil' do
        expect(subject).to eq(nil)
      end
    end

    context 'the AWS S3 client raises an exception' do
      before { allow(mock_aws_s3_client).to receive(:get_object).and_raise(StandardError) }
      let(:mock_aws_s3_response) { double('aws_s3_response') }

      it 'catches the exception and returns nil' do
        expect(subject).to eq(nil)
      end
    end
  end
end
