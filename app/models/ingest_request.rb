class IngestRequest < ApplicationRecord
  scope :ingested,       -> { where("ingested_at IS NOT NULL") }
  scope :pending_ingest, -> { where("ingested_at IS NULL") }

  validates_presence_of :uuid
  validate :not_already_pending_validation, on: :create
  after_create :send_to_fedora, on: :create

private

  def send_to_fedora
    Delayed::Job.enqueue(IngestJob.new(self.id))
  end

  def not_already_pending_validation
    if IngestRequest.pending_ingest.where(uuid: self.uuid).exists?
      errors.add(:uuid, "is already pending ingest")
    end
  end
end
