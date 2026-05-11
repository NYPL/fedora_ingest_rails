| Branch            | Status                                                                                                                                      |
|:------------------|:--------------------------------------------------------------------------------------------------------------------------------------------|
| `qa`              | [![Build Status](https://travis-ci.org/NYPL/fedora_ingest_rails.svg?branch=qa)](https://travis-ci.org/NYPL/fedora_ingest_rails)             |
| `nypl-dams-prod`  | [![Build Status](https://travis-ci.org/NYPL/fedora_ingest_rails.svg?branch=nypl-dams-prod)](https://travis-ci.org/NYPL/fedora_ingest_rails) |

## Fedora Ingest Rails

This is a Rails port of the Java application [FedoraIngest](https://github.com/NYPL/FedoraIngest/blob/qa/README.md).

It has an endpoint that [MMS](https://github.com/NYPL/mms/) hits (with
an items' UUIDs as a parameter). It records the UUID in an internal database.

Then (via DelayedJob):

* Iterates through those UUIDS and asks MMS for the latest information.
  - Asks other services (like Filestore DB) for more information about the item.

* Turns around and posts that information to Repo API Solr

## Installing & Running

This application uses [docker-compose.yml](./docker-compose.yml). **You can edit code as on your machine and expect it to hot-reload like you usually would.
Forget Docker is there.**

### Setup

1. Clone this repo.
2. In this app's root directory `cp ./.env.example ./.env`. (See directions in `.env.example` -- you should not need to change anything.)

### Running the Application

To build and start the entire stack (web app, workers, and databases), run:

`docker-compose up --build`

*Note on first run:* You may need to prepare the database before the application can fully load. Once the databases have finished initializing in the logs, open a separate terminal and run:
`docker-compose run --rm webapp bundle exec rails db:prepare`

### What Does Compose Spin Up?

It brings up the following services:

#### The App Itself

The app reachable at http://localhost:3000.
It also spins up 2 workers.

#### PostgreSQL

The app's database persists in `./database-data/postgres` of _your_ machine.

#### Filestore Databases

The filestore databases persist in `./database-data/mysql` of _your_ machine.

It brings up the moving & still image MySQL filestore databases.

## Testing

Run tests through docker-compose:

`docker-compose run webapp /bin/bash -c "cd /home/app/fedora_ingest_rails && bundle exec rspec"`

## Git Workflow & Deployment

Our branches (in order or stability are):

| Branch          | Environment | AWS Account      |
|:----------------|:------------|:-----------------|
| qa              | qa          | nypl-dams-dev    |
| nypl-dams-prod  | production  | nypl-dams-prod   |

### Cutting A Feature Branch

1. Feature branches are cut from `qa`.
2. Once the feature branch is ready to be merged, file a pull request of the branch _into_ qa.
3. We 'promote' branches by merging from the less mature branch to the more mature branch. (qa => nypl-dams-prod) 

### Deploying

We use Travis for continuous deployment.
Merging to certain branches automatically deploys to the environment associated to
that branch.

| Merge from  | Into              | Deploys to (after tests pass) |
|:------------|:------------------|:------------------------------|
| `your-pr`   | `qa`              | qa env                        |
| `qa`        | `nypl-dams-prod`  | production env                |

For insight into how CD works look at [.travis.yml](./.travis.yml) and the
[provisioning/travis_ci_and_cd](./provisioning/travis_ci_and_cd) directory.
The approach is inspired by [this blog post](https://dev.mikamai.com/2016/05/17/continuous-delivery-with-travis-and-ecs/) ([google cached version](https://webcache.googleusercontent.com/search?q=cache:NodZ-GZnk6YJ:https://dev.mikamai.com/2016/05/17/continuous-delivery-with-travis-and-ecs/+&cd=1&hl=en&ct=clnk&gl=us&client=firefox-b-1-ab)).

## Amazon & ECS Deployment Configuration

See [Amazon And ECS](./documentation/amazon-and-ecs.md).

## Debugging

You may want to start a rails console or hit an endpoint for debugging purposes.  
See the [debugging documentation](./documentation/debugging.md).
 
