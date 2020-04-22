#!/bin/bash

regex='refs/heads/(.*)'
[[ "$BRANCH" =~ $regex ]]
SIMPLE_BRANCH=${BASH_REMATCH[1]}
echo "Will post result: {\"project\":\"enroll_dc\",\"branch\":\"$SIMPLE_BRANCH\",\"sha\":\"$SHA\",\"status\":\"$STATUS\"}"

deployenv='false'
if [ "${SIMPLE_BRANCH}" == *"tag"* ]
then
  deployenv='preprod'
fi

curl -G -v http://34.225.168.86:2201/job/deploy/buildWithParameters --data-urlencode "text=enroll ${BRANCH} ${deployenv}" --data-urlencode "username=davidplappert" --data-urlencode "response_url=https://dchbx.com" --data-urlencode "jenkins_branch_name=${SIMPLE_BRANCH}"
