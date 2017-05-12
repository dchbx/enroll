#!/bin/bash

exit_code=0

echo "*** Running ACA::Individual engine specs"
bundle install  --jobs=3 --retry=3 | grep Installing
bundle exec rspec
exit_code+=$?

exit $exit_code
