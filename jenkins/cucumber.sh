#!/bin/bash

base="$( dirname "${BASH_SOURCE[0]}" )/.."

cd $base
root=`pwd -P`

rm -rf ./log/test.log
rm -rf ./coverage
rm -rf ./tmp/rspec_junit_*.xml
rm -rf ./public/packs*

bundle install

[[ -s $HOME/.nvm/nvm.sh ]] && . $HOME/.nvm/nvm.sh
nvm install 10
nvm use 10 || exit -1
npm install --global yarn
yarn install

bundle exec rails r -e test "DatabaseCleaner.clean"

### Run cucumber
rm -fr tmp/cucumber.log tmp/cucumber_failures.log tmp/cucumber_failures2.log tmp/cucumber_failures3.log tmp/cucumber_failures4.log tmp/cucumber_failures_2.log tmp/cucumber_failures_3.log cucumber.summary cucumber2.summary cucumber3.summary cucumber4.summary cucumber_2.summary cucumber_3.summary
if bundle exec parallel_test features --type cucumber -n 4
then
  echo "Cucumber passed the first time!"
  exit 0
else
  echo "Give cucumber one more try"
  if bundle exec cucumber @tmp/cucumber_failures.log @tmp/cucumber_failures2.log @tmp/cucumber_failures3.log @tmp/cucumber_failures4.log --format summary --out cucumber_2.summary --format rerun --out tmp/cucumber_failures_2.log
  then
    echo "Cucumber worked on retry"
    exit 0
  else
    echo "Give cucumber yet another try"
    bundle exec cucumber @tmp/cucumber_failures_2.log --format summary --out cucumber_3.summary --format rerun --out tmp/cucumber_failures_3.log
  fi
fi

if [ -f 'cucumber3.summary' ]; then
  echo "We ran at least 3 times, checking for error output"
  cucumber_results=$(tail -3 cucumber_3.summary | head -1 | sed -e 's/.* (\(.*\) failed.*/\1/')
  result_count=${cucumber_results##*[!0-9]}

  if [[ $result_count -ne 0 ]]; then
    failure_count=$(($result_count + 0))
    if  [[ $failure_count -gt 126 ]]; then
      exit_code=126
    else
      exit_code=$failure_count
    fi
  fi
fi

exit $exit_code
