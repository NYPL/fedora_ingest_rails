# frozen_string_literal: true

require 'rails_helper'

RSpec.describe ImageFilestoreEntry, type: :model do
  it 'Should be readonly' do
    expect(build(:image_filestore_entry)).to be_readonly
  end

  it 'Should be readonly' do
    expect(ImageFilestoreEntry.new).to be_readonly
  end

  it 'Should not be able to save' do
    entry = build(:image_filestore_entry)
    expect { entry.save }.to raise_error(ActiveRecord::ReadOnlyRecord)
  end

  it 'Should always have an unknown key in the mimetype dictionary' do
    key_exists = ImageFilestoreEntry.new.mimetypes_dictionary['unknown'].present?
    expect(key_exists).to eq(true)
  end

  it 'Should always have a types dictionary' do
    expect(ImageFilestoreEntry.new.types_dictionary.present?).to eq(true)
  end

  it 'Should return value of Unknown for garbage types' do
    expect(ImageFilestoreEntry.new.get_type('Larry!')).to eq('Unknown')
  end

  it 'Should return value types for good types' do
    expect(ImageFilestoreEntry.new.get_type('j')).to eq('JP2')
  end

  it 'Should return value for unknown mimetype key for garbage mimetypes' do
    expect(ImageFilestoreEntry.new.get_mimetype('Larry!')).to eq(ImageFilestoreEntry.new.mimetypes_dictionary['unknown'])
  end
end
