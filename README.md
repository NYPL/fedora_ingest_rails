| Branch   | Status                                                                                                                                    |
|:---------|:------------------------------------------------------------------------------------------------------------------------------------------|
| `master` | [![Build Status](https://travis-ci.org/NYPL-Simplified/circulation.svg?branch=master)](https://travis-ci.org/NYPL-Simplified/circulation) |

## Fedora Ingest Rails

This is a Rails port of the Java application [FedoraIngest](https://github.com/NYPL/FedoraIngest/blob/master/README.md).

It an endpoint that [MMS](https://bitbucket.org/NYPL/mms/) hits (with
an items' UUIDs as a parameter). It records the UUID in an internal database.

Then (via DelayedJob):

* Iterates through those UUIDS and asks MMS for the latest information.
  - Asks other services (like Filestore DB) for more information about the item.

* Turns around and posts that information to Fedora.

This decouples MMS from direct communication with Fedora in the event of Fedora API changes or downtime.

## Installing

### Creating and boostrapping Databases

In addition to its own database, this application communicates to

* A MySQL database that stores the images that are in isilon.
* A MySQL database that stores audio/videos that are in isilon.

They are in different databases for historic reasons and one
day, they should be combined.

#### Bootstrapping the image filestore database

1. Create MySQL Database
  - `create database ami_filestore_development;`
  - `create database ami_filestore_test;`
  - `create database image_filestore_development;`
  - `create database image_filestore_test;`
  
2. Load its contents with a command like `mysql -uroot DBNAME < ./db/resources/image_filestore_schema.sql`

#### Bootstrapping the AMI filestore database

1. Create a MySQL database
2. Load its contents with a command like `mysql -uroot DBNAME < ./db/resources/ami_filestore_schema.sql`

### Setting Environment Variables

Copy `./.env.example` to `./.env`.

Fill it out with:

* Credentials to the two databases mentioned above.
* Host and credentials for making requests to MMS's API.
* Host and credentials for connecting to Fedora.

## Running Delayed Job

The rails application accepts work by being hit by HTTP requests but
does all its hard work in DelayedJob workers. This allows it to answer
requests quickly while being horizontally scalable by spinning up
additional workers.

## Git Workflow & Deployment

* TODO: Fill this in...
