#!/bin/bash

base="$( dirname "${BASH_SOURCE[0]}" )/.."

cd $base
root=`pwd -P`

rm -Rf ./doc ./rubocop ./angular_documentation ./angular_coverage rdocs.zip tmp/incremental_angular_TEST.xml

bundle exec yardoc
bundle exec rubocop -f h -o rubocop/index.html

nvm use 10
yarn install
yarn run ng test --code-coverage
yarn run angular-docs

zip -r rdocs.zip doc rubocop angular_documentation angular_coverage
