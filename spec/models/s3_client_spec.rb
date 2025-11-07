# frozen_string_literal: true

require 'rails_helper'

RSpec.describe S3Client, type: :model do
  before { allow(Aws::S3::Client).to receive(:new).and_return(mock_aws_s3_client) }
  let(:mock_aws_s3_client) { double('aws_s3_client', :get_object => mock_aws_s3_response) }

  describe '#ocr_for' do
    subject { S3Client.new.ocr_for(uuid) }
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

    context 'the hocr gets returned' do
      let(:mock_aws_s3_response) { double('aws_s3_response', :body => mock_aws_s3_response_body) }
      let(:mock_aws_s3_response_body) { double('aws_s3_response_body', :read => hocr) }
      let(:hocr) { "<?xml version=\"1.0\" encoding=\"UTF-8\"?><!DOCTYPE html PUBLIC \"-//W3C//DTD XHTML 1.0 Transitional//EN\" \"http://www.w3.org/TR/xhtml1/DTD/xhtml1-transitional.dtd\"><html xmlns=\"http://www.w3.org/1999/xhtml\" xml:lang=\"en\" lang=\"en\"><head><title></title><meta http-equiv=\"Content-Type\" content=\"text/html;charset=utf-8\" /><meta name='ocr-system' content='tesseract 3.04.00' /><meta name='ocr-capabilities' content='ocr_page ocr_carea ocr_par ocr_line ocrx_word'/></head><body><div class='ocr_page' id='page_1' title='image \"./1962/5215078g.jpg\"; bbox 0 0 3041 4044; ppageno 0'><div class='ocr_carea' id='block_1_1' title=\"bbox 0 0 532 404\"><p class='ocr_par' dir='ltr' id='par_1_1' title=\"bbox 0 0 532 404\"><span class='ocr_line' id='line_1_1' title=\"bbox 0 0 532 404; baseline 0 3640\"><span class='ocrx_word' id='word_1_1' title='bbox 0 0 532 404; x_wconf 95' lang='eng' dir='ltr'></span></span></p></div><div class='ocr_carea' id='block_1_2' title=\"bbox 1249 425 1777 493\"><p class='ocr_par' dir='ltr' id='par_1_2' title=\"bbox 1249 425 1777 493\"><span class='ocr_line' id='line_1_2' title=\"bbox 1249 425 1777 493; baseline 0 -12\"><span class='ocrx_word' id='word_1_2' title='bbox 1249 425 1409 483; x_wconf 91' lang='eng' dir='ltr'>New</span><span class='ocrx_word' id='word_1_3' title='bbox 1440 426 1604 482; x_wconf 88' lang='eng' dir='ltr'><strong>York</strong></span><span class='ocrx_word' id='word_1_4' title='bbox 1635 425 1777 493; x_wconf 82' lang='eng' dir='ltr'><strong>City</strong></span></span></p></div></div></body></html>" }
      let(:expected_return_value) { "<!DOCTYPE html PUBLIC \"-//W3C//DTD XHTML 1.0 Transitional//EN\" \"http://www.w3.org/TR/xhtml1/DTD/xhtml1-transitional.dtd\"> <?xml version=\"1.0\" encoding=\"UTF-8\"?><html xmlns=\"http://www.w3.org/1999/xhtml\" xml:lang=\"en\" lang=\"en\"> <head> <title></title> <meta http-equiv=\"Content-Type\" content=\"text/html;charset=utf-8\"> <meta name=\"ocr-system\" content=\"tesseract 3.04.00\"> <meta name=\"ocr-capabilities\" content=\"ocr_page ocr_carea ocr_par ocr_line ocrx_word\"> </head> <body><div class=\"ocr_page\" id=\"page_1\" title='image \"./1962/5215078g.jpg\"; bbox 0 0 3041 4044; ppageno 0'> <div class=\"ocr_carea\" id=\"block_1_1\" title=\"bbox 0 0 532 404\"><p class=\"ocr_par\" dir=\"ltr\" id=\"par_1_1\" title=\"bbox 0 0 532 404\"><span class=\"ocr_line\" id=\"line_1_1\" title=\"bbox 0 0 532 404; baseline 0 3640\"><span class=\"ocrx_word\" id=\"word_1_1\" title=\"bbox 0 0 532 404; x_wconf 95\" lang=\"eng\" dir=\"ltr\"></span></span></p></div> <div class=\"ocr_carea\" id=\"block_1_2\" title=\"bbox 1249 425 1777 493\"><p class=\"ocr_par\" dir=\"ltr\" id=\"par_1_2\" title=\"bbox 1249 425 1777 493\"><span class=\"ocr_line\" id=\"line_1_2\" title=\"bbox 1249 425 1777 493; baseline 0 -12\"><span class=\"ocrx_word\" id=\"word_1_2\" title=\"bbox 1249 425 1409 483; x_wconf 91\" lang=\"eng\" dir=\"ltr\">New</span><span class=\"ocrx_word\" id=\"word_1_3\" title=\"bbox 1440 426 1604 482; x_wconf 88\" lang=\"eng\" dir=\"ltr\"><strong>York</strong></span><span class=\"ocrx_word\" id=\"word_1_4\" title=\"bbox 1635 425 1777 493; x_wconf 82\" lang=\"eng\" dir=\"ltr\"><strong>City</strong></span></span></p></div> </div></body> </html>" }

      it 'returns the expected unescaped hocr string' do
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
