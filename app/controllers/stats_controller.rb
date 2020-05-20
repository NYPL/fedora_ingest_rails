# frozen_string_literal: true

class StatsController < ApplicationController
  def show
    # Delayed::Job Related
    workable_job_arel = Delayed::Job.where(last_error: nil)
    @errored_jobs_count = Delayed::Job.where.not(last_error: nil).count
    @workable_jobs_count = workable_job_arel.count
    @total_jobs_count = Delayed::Job.count
    @oldest_workable_job = workable_job_arel.order('created_at ASC').first

    # IngestRequest Related
    @total_ingested_count = IngestRequest.ingested.count
    @total_pending_ingest_count = IngestRequest.pending_ingest.count
    @total_ingest_requests_count = IngestRequest.count
    @oldest_not_ingested = IngestRequest.pending_ingest.order('created_at ASC').first
    @last_ingested = IngestRequest.ingested.last
  end
end
