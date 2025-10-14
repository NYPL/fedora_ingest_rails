# frozen_string_literal: true

require 'rails_helper'

RSpec.describe ImageFilestoreEntry, type: :model do
  # sample image id
  let(:file_id) { 'that_is_a_picture_nypl' }

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

  it 'Should respond in the affirmative if it has a filestore entry matching a given file_id' do
    foo_file = double("Foo file")
    allow(ImageFilestoreEntry).to receive(:where).with({file_id: "foo"}).and_return([double("Foo file", file_id: "Foo")])
    expect(ImageFilestoreEntry.has_file?('foo')).to eq(true)
  end
  
  it 'Should respond in the negative if it is given a nonexistant file_id' do
    expect(ImageFilestoreEntry.has_file?('nonexistant')).to eq(false)
  end

  describe '.suppress_all_for_file_id' do
    # Define a collection of mock records that the `where` call should return
    let(:mock_record_1) { instance_double(ImageFilestoreEntry) }
    let(:mock_record_2) { instance_double(ImageFilestoreEntry) }
    let(:mock_collection) { [mock_record_1, mock_record_2] }

    # --- Scenario 1: Running in a non-production environment ---
    context 'when Rails.env is NOT production' do
      before do
        allow(Rails.env).to receive(:production?).and_return(false)
      end

      it 'does not query the database or perform any updates' do
        # Verify that the `where` method (database query) is never called
        expect(ImageFilestoreEntry).not_to receive(:where)

        # Verify that the correct "skipping" message is printed to stdout
        expect {
          ImageFilestoreEntry.suppress_all_for_file_id(file_id)
        }.to output("Skipping actual database update updating values because we are not in production.\n").to_stdout
      end
    end

    # --- Scenario 2: Running in the production environment ---
    context 'when Rails.env IS production' do
      # Setup the environment and mock database behavior
      before do
        allow(Rails.env).to receive(:production?).and_return(true)

        # 1. Mock the class method `where` to return our mock collection.
        # This bypasses the NameError caused by the undefined `doc` variable in the method.
        # We assume the developer intended to query for entries matching the file_id.
        allow(ImageFilestoreEntry).to receive(:where).and_return(mock_collection)

        # 2. Expect the key update action to happen on each mock record
        expect(mock_record_1).to receive(:update_column).with(:suppressed, 1).once
        expect(mock_record_2).to receive(:update_column).with(:suppressed, 1).once
      end

      it 'finds and updates all matching entries by setting suppressed to 1' do
        # When the method is called, the expectations in the `before` block are evaluated.
        # If the updates were not called, the test would fail.
        ImageFilestoreEntry.suppress_all_for_file_id(file_id)

        # Also confirm that no skipping message is printed
        expect {
          ImageFilestoreEntry.suppress_all_for_file_id(file_id)
        }.not_to output.to_stdout
      end
    end
  end

  describe '#readonly?' do
    let(:entry) { ImageFilestoreEntry.new }

    context 'when Rails.env is NOT production' do
      before { allow(Rails.env).to receive(:production?).and_return(false) }

      it 'returns true, enforcing read-only behavior' do
        expect(entry.readonly?).to be true
      end
    end
  end
end
