#!/bin/bash

exit_code=0

echo "*** Running TransportGateway engine specs"
#bundle install --jobs=3 --retry=3
# bundle exec rake db:create db:migrate
# RAILS_ENV=test bundle exec rake db:create db:migrate

bundle exec rspec spec
exit_code+=$?

exit $exit_code