require 'rails_helper'

RSpec.describe SingleFieldUpdatesController, type: :controller do
  describe '#validate_json_and_format' do
    let(:valid_updates_array) do
      [{ uuid: 'some_uuid', field_name: 'some_field', field_value: 'some_value' }]
    end

    let(:invalid_json_updates_array) do
      'invalid_json_string'
    end

    let(:invalid_updates_array) do
      [{ missing_key: 'value' }]
    end

    it 'returns true and success message for valid JSON and format' do
      result, message = SingleFieldUpdatesController.new.send(:validate_json_and_format, valid_updates_array)
      expect(result).to be_truthy
      expect(message).to eq('Valid JSON and format')
    end

    it 'returns false and error message for invalid JSON' do
      result, message = SingleFieldUpdatesController.new.send(:validate_json_and_format, invalid_json_updates_array)
      expect(result).to be_falsey
      expect(message).to eq('Invalid body format for method.')
    end

    it 'returns false and error message for invalid updates array values' do
      result, message = SingleFieldUpdatesController.new.send(:validate_json_and_format, invalid_updates_array)
      expect(result).to be_falsey
      # Adjust the error message based on your implementation
      expect(message).to eq('Invalid entry format in "single_field_values"')
    end
  end

  describe '#update_fields' do
    let(:valid_single_field_updates) do
      [{ uuid: 'some_uuid', field_name: 'some_field', field_value: 'some_value' }]
    end

    it 'renders a bad request if validation fails' do
      allow(controller).to receive(:validate_json_and_format).and_return([false, 'Invalid JSON'])

      post :update_fields

      expect(response).to have_http_status(:bad_request)
      expect(JSON.parse(response.body)).to eq('error' => 'Invalid JSON')
    end

    it 'renders ok and enqueues jobs if validation passes' do
      allow(controller).to receive(:validate_json_and_format).and_return([true, 'Valid JSON and format'])
      allow(controller).to receive(:params).and_return(single_field_updates: valid_single_field_updates)

      expect {
        post :update_fields
      }.to change { Delayed::Job.count }.by(1)

      expect(response).to have_http_status(:ok)
    end
  end
end
