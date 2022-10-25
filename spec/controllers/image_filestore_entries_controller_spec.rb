# frozen_string_literal: true

require 'rails_helper'

RSpec.describe ImageFilestoreEntriesController, type: :controller do
  
  it "will respond to status requests with 404 if not found" do
    get :status, params: { file_id: 'AwesomePhoto_BaronVonGroovy' }, format: :json
    expect(response.status).to eq(404)
  end
  
  it "will respond to status requests with 200 if found" do
    foo_file = double("Foo file")
    allow(ImageFilestoreEntry).to receive(:where).with({file_id: "foo"}).and_return([double("Foo file", file_id: "Foo")])
    get :status, params: { file_id: 'foo' }, format: :json
    expect(response.status).to eq(200)
  end
  
end
