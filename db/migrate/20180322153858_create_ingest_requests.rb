# frozen_string_literal: true

class CreateIngestRequests < ActiveRecord::Migration[5.0]
  def change
    create_table :ingest_requests do |t|
      t.string :uuid
      t.timestamp :ingested_at
      t.timestamps
    end
    add_index :ingest_requests, :uuid
  end
end
