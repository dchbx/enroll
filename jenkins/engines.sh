#!/bin/bash

result=0

base="$( dirname "${BASH_SOURCE[0]}" )/.."
cd $base
root=`pwd -P`

bundle install

rm -rf ./log/test.log
rm -rf ./coverage
rm -rf ./tmp/rspec_junit_*.xml
rm -rf ./public/packs*

[[ -s $HOME/.nvm/nvm.sh ]] && . $HOME/.nvm/nvm.sh
nvm install 10
nvm use 10 || exit -1
npm install --global yarn
yarn install

NODE_ENV=test RAILS_ENV=test ./bin/webpack || exit 1

for test_dir in `ls -1 $root/components/ | grep -v old_sponsored_benefits`; do
  echo $root/components/$test_dir
  cd $root/components/$test_dir
  bundle install
  bundle exec rspec --fail-fast
  ((result+=$?))
  if [ $result -ne 0 ]; then
    echo "ENGINE FAILED"
	  exit $result
  fi
done

exit $result