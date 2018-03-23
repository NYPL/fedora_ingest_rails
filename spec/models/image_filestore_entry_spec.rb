require 'rails_helper'

RSpec.describe ImageFilestoreEntry, type: :model do
  it 'Should be readonly' do
    expect(build(:image_filestore_entry)).to be_readonly
  end

  it 'Should be readonly' do
    expect(AmiFilestoreEntry.new).to be_readonly
  end

  it 'Should not be able to save' do
    entry = build(:image_filestore_entry)
    expect { entry.save }.to raise_error(ActiveRecord::ReadOnlyRecord)
  end
end
