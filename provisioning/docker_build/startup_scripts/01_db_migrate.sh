#!/bin/bash

if [ "$RAILS_ENV" == "development" ]; then
  echo "Waiting for postgres to be healthy enough to come up"
  sleep 10
fi

cd /home/app/fedora_ingest_rails && RAILS_ENV=$RAILS_ENV bundle exec rake db:create db:migrate
