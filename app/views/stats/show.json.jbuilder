# frozen_string_literal: true

json.delayedJobs do
  json.totalJobsCount @total_jobs_count
  json.workableJobsCount @workable_jobs_count
  json.erroredJobsCount @errored_jobs_count
  json.oldestWorkableJob @oldest_workable_job
end

json.IngestRequests do
  json.ingestedCount @total_ingested_count
  json.pendingIngestCount @total_pending_ingest_count
  json.totalIngestCount @total_ingest_requests_count
  json.oldestNotIngested @oldest_not_ingested
  json.lastIngested @last_ingested
end
