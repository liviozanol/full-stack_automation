#!/bin/bash
PHYSICAL_NET_DEVICES=`find /sys/class/net -type l -not -lname '*virtual*' -printf '%f\n' | head -1`
PHYSICAL_IP_ADDRESS=`ip add show $PHYSICAL_NET_DEVICES | grep "inet " | cut -d" " -f6 | cut -d "/" -f1`
GITLAB_URL="http://127.0.0.1:10000/"
if [ $# -ne 0 ]; then
    GITLAB_URL="$1"
fi

GITLAB_TOKEN="fullstack-automation"
if [ $# -ge 2 ]; then
    GITLAB_TOKEN="$2"
fi

#Changing 127.0.0.1 API IP to host IP
#Changing 127.0.0.1 API IP to host IP
sed -i 's/127.0.0.1:8000/'"$PHYSICAL_IP_ADDRESS"':12345/' src/App.js
#Changing 127.0.0.1 API IP to host IP
#Changing 127.0.0.1 API IP to host IP

GROUP_ID=`cat ../api/tmp_group_id.tmp`
#Creating project
PROJECT_ID=`curl --noproxy "*" --request POST --header "PRIVATE-TOKEN: $GITLAB_TOKEN" \
     --header "Content-Type: application/json" \
     --data '{"name": "ui", "namespace_id": '"$GROUP_ID"' }' \
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
git push --set-upstream http://gitlab-ci-token:fullstack-automation@127.0.0.1:10000/api_ui/ui master