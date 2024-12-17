# frozen_string_literal: true

class IngestRequest < ApplicationRecord
  scope :ingested,       -> { where('ingested_at IS NOT NULL') }
  scope :pending_ingest, -> { where('ingested_at IS NULL') }

  validates_presence_of :uuid
  validate :not_already_pending_validation, if: :new_record?

  attr_accessor :test_mode

  private

  def not_already_pending_validation
    if IngestRequest.pending_ingest.where(uuid: uuid).exists?
      errors.add(:uuid, 'is already pending ingest')
    end
  end
end
