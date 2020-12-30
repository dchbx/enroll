#!/bin/bash

result=0
root=`pwd -P`

for test_dir in `ls -1 $root/components/ | grep -v old_sponsored_benefits`; do
  echo $test_dir
  cd $root/components/$test_dir
  ls
  ((result+=$?))
  if [ $result -ne 0 ]; then
    echo "ENGINE FAILED"
    exit $result
  fi
done
