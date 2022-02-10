#!/bin/bash
GITLAB_URL="http://127.0.0.1:10000/"
if [ $# -ne 0 ]; then
    GITLAB_URL="$1"
fi

GITLAB_TOKEN="fullstack-automation"
if [ $# -ge 2 ]; then
    GITLAB_TOKEN="$2"
fi


GROUP_ID=`cat ../api/tmp_group_id.tmp`
#Creating project
PROJECT_ID=`curl --noproxy "*" --request POST --header "PRIVATE-TOKEN: $GITLAB_TOKEN" \
     --header "Content-Type: application/json" \
     --data '{"name": "bastion", "namespace_id": '"$GROUP_ID"' }' \
     "$GITLAB_URL/api/v4/projects/" | jq .id`


#Submitting files
git init
git config user.email "fullstackauto@localhost.local"
sleep 1
git config user.name "fullstackauto"
sleep 1
git add .
git commit -m "initial commit"
sleep 2
git push --set-upstream http://gitlab-ci-token:fullstack-automation@127.0.0.1:10000/api_ui/bastion master