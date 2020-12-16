| Branch       | Status                                                                                                                                  |
|:-------------|:----------------------------------------------------------------------------------------------------------------------------------------|
| `master`     | [![Build Status](https://travis-ci.org/NYPL/fedora_ingest_rails.svg?branch=master)](https://travis-ci.org/NYPL/fedora_ingest_rails)     |
| `qa`         | [![Build Status](https://travis-ci.org/NYPL/fedora_ingest_rails.svg?branch=qa)](https://travis-ci.org/NYPL/fedora_ingest_rails)         |
| `production` | [![Build Status](https://travis-ci.org/NYPL/fedora_ingest_rails.svg?branch=production)](https://travis-ci.org/NYPL/fedora_ingest_rails) |


## Fedora Ingest Rails

This is a Rails port of the Java application [FedoraIngest](https://github.com/NYPL/FedoraIngest/blob/master/README.md).

It has an endpoint that [MMS](https://bitbucket.org/NYPL/mms/) hits (with
an items' UUIDs as a parameter). It records the UUID in an internal database.

Then (via DelayedJob):

* Iterates through those UUIDS and asks MMS for the latest information.
  - Asks other services (like Filestore DB) for more information about the item.

* Turns around and posts that information to Fedora & RELS-EXT Solr

This decouples MMS from direct communication with Fedora in the event of Fedora API changes or downtime.

## Installing & Running

This application uses [docker-compose.yml](./docker-compose.yml) to for _most_ of what it needs.
As time goes on, we'll Dockerize more dependencies and have `docker-compose` be
one-stop shopping for running locally. **You can edit code as on your machine and expect it to hot-reload like you usually would.
Forget Docker is there.**

### Setup

1. Clone this repo.
1. Clone [NYPL/fedoracommons-3.4.2-dockerized](https://github.com/NYPL/fedoracommons-3.4.2-dockerized) & [NYPL/filestore_databases_docker](https://github.com/NYPL/filestore_databases_docker) in the directory above this. (make them siblings of this app)
1. In this app's root directory `cp ./.env.example ./.env` and fill it out. (See directions in `.env.example`)

#### Setting Up Databases (first run)

1.  Run `docker-compose up filestore-db postgres`, wait, let the databases be created, and synched/mounted to ./database-data.
The output will slow down after ~30 seconds.
1.  Now, in another terminal run `docker-compose run webapp`, this will create the database and run the migrations.
1.  Once the migrations end you can `crtl-z` and stop the services

### Running

`docker-compose up --scale worker=2`

### What Does Compose Spin Up?

It brings up the following services:

#### The App Itself

The app reachable at http://localhost:3000.
It also spins up 2 workers.

#### PostgreSQL

The app's database persists in `./database-data/postgres` of _your_ machine.

#### Fedora

Our [dockerized Fedora instance](https://github.com/NYPL/fedoracommons-3.4.2-dockerized) reachable at http://localhost:8080.

#### Filestore Databases

The app's database persists in `./database-data/postgres` of _your_ machine.

It brings up the moving & still image MySQL filestore databases.
Change your `.env` file if you want to connect to a remote filestore.

## Testing

Run tests through docker-compose:

`docker-compose run webapp /bin/bash -c "cd /home/app/fedora_ingest_rails && bundle exec rspec"`

## Git Workflow & Deployment

Our branches (in order or stability are):

| Branch     | Environment | AWS Account      |
|:-----------|:------------|:-----------------|
| master     | none        | none             |
| qa         | qa          | nypl-digital-dev |
| production | production  | nypl-digital-dev |

### Cutting A Feature Branch

1. Feature branches are cut from `master`.
2. Once the feature branch is ready to be merged, file a pull request of the branch _into_ master.
3. We 'promote' branches by merging from the less mature branch to the more mature branch. (master => qa => production) 

### Deploying

We use Travis for continuous deployment.
Merging to certain branches automatically deploys to the environment associated to
that branch.

| Merge from | Into         | Deploys to (after tests pass) |
|:-----------|:-------------|:------------------------------|
| `master`   | `qa`         | qa env                        |
| `qa`       | `production` | production env                |

For insight into how CD works look at [.travis.yml](./.travis.yml) and the
[provisioning/travis_ci_and_cd](./provisioning/travis_ci_and_cd) directory.
The approach is inspired by [this blog post](https://dev.mikamai.com/2016/05/17/continuous-delivery-with-travis-and-ecs/) ([google cached version](https://webcache.googleusercontent.com/search?q=cache:NodZ-GZnk6YJ:https://dev.mikamai.com/2016/05/17/continuous-delivery-with-travis-and-ecs/+&cd=1&hl=en&ct=clnk&gl=us&client=firefox-b-1-ab)).

## Amazon & ECS Deployment Configuration

See [Amazon And ECS](./documentation/amazon-and-ecs.md).

## Debugging

You may want to start a rails console or hit an endpoint for debugging purposes.  
See the [debugging documentation](./documentation/debugging.md).
