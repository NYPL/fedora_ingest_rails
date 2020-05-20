# frozen_string_literal: true

require 'rails_helper'

RSpec.describe AmiFilestoreEntry, type: :model do
  it { is_expected.to belong_to(:source) }

  it 'Should be readonly' do
    expect(AmiFilestoreEntry.new).to be_readonly
  end

  it 'Should not be able to save' do
    entry = build(:ami_filestore_entry)
    expect(entry).to be_valid
    expect { entry.save }.to raise_error(ActiveRecord::ReadOnlyRecord)
  end
end
