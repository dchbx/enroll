#!/bin/bash

base="$( dirname "${BASH_SOURCE[0]}" )/.."

cd $base
root=`pwd -P`

bundle exec yardoc
bundle exec rubocop -f h -o rubocop/index.html
