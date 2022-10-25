# frozen_string_literal: true

require 'rails_helper'

RSpec.describe ImageFilestoreEntriesController, type: :controller do
  
  it "will respond to status requests with 404 if not found" do
    get :status, params: { file_id: 'AwesomePhoto_BaronVonGroovy' }, format: :json
    expect(response.status).to eq(404)
  end
  
end
