# frozen_string_literal: true

FactoryBot.define do
  factory :source do
    uuid '123'
    name 'foo'
    is_processed true
    source 'whoknows'
  end

  factory :ingest_request do
    uuid 'MyString'
  end

  factory :ami_filestore_entry do
    name 'hi'
    checksum 'abc'
    capture_uuid '123-456'
    is_processed true
    uuid '123'
    size 123
    source_id 12
    source
  end

  factory :image_filestore_entry do
    file_name 'foo'
    checksum 'foo'
    type 's'
    uuid 'foo'
    cdate Time.now
  end
end
