#!/bin/bash
cd /home/app/fedora_ingest_rails && RAILS_ENV=production bundle exec rake db:migrate
