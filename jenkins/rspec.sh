#!/bin/bash

result=0

base="$( dirname "${BASH_SOURCE[0]}" )/.."
cd $base
root=`pwd -P`

rm -rf ./log/test.log
rm -rf ./spec/vocabularies
rm -rf ./coverage
rm -rf ./tmp/rspec_junit_*.xml
rm -rf ./public/packs*

[[ -s $HOME/.nvm/nvm.sh ]] && . $HOME/.nvm/nvm.sh
nvm install 10
nvm use 10 || exit -1
npm install --global yarn
yarn install

NODE_ENV=test RAILS_ENV=test ./bin/webpack

cd $root

bundle install

bundle exec rails r -e test "DatabaseCleaner.clean"

COVERAGE=true bundle exec rake parallel:spec[4]