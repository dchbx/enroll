#!/bin/bash

result=0

base="$( dirname "${BASH_SOURCE[0]}" )/.."
cd $base
root=`pwd -P`

rm -rf ./log/test.log
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

COVERAGE=true bundle exec parallel_test spec components/benefit_markets/spec components/benefit_sponsors/spec components/notifier/spec components/sponsored_benefits/spec components/transport_gateway/spec components/transport_profiles/spec --type rspec -n 4
