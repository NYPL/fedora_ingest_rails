require 'rails_helper'

RSpec.describe PermalinkClient, type: :model do
  before do
    @permalink_client = PermalinkClient.new(
      base_url:   'http://minter.example.com/',
      lookup_url: 'http://minter.example.com/link-admin/lookup',
      minter_url: 'http://minter.example.com/link-admin/records',
      basic_username: 'FrankColumbo',
      password: 'justonemorething1'
    )
  end
end
