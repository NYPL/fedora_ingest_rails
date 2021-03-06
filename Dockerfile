FROM phusion/passenger-ruby26:1.0.9 AS production

# Set correct environment variables.
ENV HOME /root

# Use baseimage-docker's init process.
RUN mkdir -p /etc/my_init.d
ADD ./provisioning/docker_build/startup_scripts/01_db_migrate.sh /etc/my_init.d/01_db_migrate.sh
CMD ["/sbin/my_init"]

EXPOSE 80
RUN apt-get update
# https://github.com/phusion/passenger-docker/issues/195
RUN apt-get install -y tzdata

# So nginx won't clear the environment variables (see notes in environment-variables.conf)
ADD ./provisioning/docker_build/environment-variables.conf /etc/nginx/main.d/environment-variables.conf

# Passenger Configuration & App
RUN rm /etc/nginx/sites-enabled/default
ADD ./provisioning/docker_build/fedora_ingest_rails.conf /etc/nginx/sites-enabled/fedora_ingest_rails.conf
COPY --chown=app:app . /home/app/fedora_ingest_rails

## Bundle Gems
# https://stackoverflow.com/questions/47972479/after-ruby-update-to-2-5-0-require-bundler-setup-raise-exception
RUN cd /home/app/fedora_ingest_rails && gem update --system
RUN cd /home/app/fedora_ingest_rails && gem install bundler
RUN cd /home/app/fedora_ingest_rails && BUNDLER_WITHOUT="development test" bundle install

# Enables ngnix+passenger
RUN rm -f /etc/service/nginx/down

# Clean up APT when done.
RUN apt-get clean && rm -rf /var/lib/apt/lists/* /tmp/* /var/tmp/*

FROM production AS development

RUN cd /home/app/fedora_ingest_rails && rm -rfv .bundle
RUN cd /home/app/fedora_ingest_rails && BUNDLER_WITH="development test" bundle
# It will be linked from localhost
RUN rm -rf /home/app/fedora_ingest_rails/*
