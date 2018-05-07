# Debugging

## Basic Information

Some basic information is available `curl`ing or going to: `http://[APP-DOMAIN]/stats`:

```json
{
  "delayedJobs" : {
     "totalJobsCount" : 46745,
     "workableJobsCount" : 46434,
     "erroredJobsCount" : 311,
     "oldestWorkableJob" : ...snip,
  },
   "IngestRequests" : {
      "lastIngested" : {
         "updated_at" : "2018-05-02T15:53:59.828Z",
         "uuid" : "bd6ec320-0ef7-0133-edf1-58d385a7b928",
         "id" : 113723,
         "ingested_at" : "2018-05-02T15:53:59.827Z",
         "created_at" : "2018-05-01T21:29:41.882Z"
      }...snip,
      "totalIngestCount" : 113572,
      "pendingIngestCount" : 46745,
      "ingestedCount" : 66827
   }
}
```

## Logging into a Running Container on an ECS Host

1. SSH onto one of the ECS hosts in the cluster: `ssh -i /path/to/private-key ec2-user@[AN-IP-ADDRESS]`.
2. Get into a running container: `docker exec -it [SHA from 'docker ps'] /bin/bash`
3. Inside container, switch to its `app` user: `su app`
4. `cd ~/fedora_ingest_rails && bundle exec rails c`
