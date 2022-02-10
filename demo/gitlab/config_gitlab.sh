#!/bin/bash
GITLAB_URL="http://127.0.0.1:10000"
if [ $# -ne 0 ]; then
    GITLAB_URL="$1"
fi

GITLAB_TOKEN="fullstack-automation"
if [ $# -eq 2 ]; then
    GITLAB_TOKEN="$2"
fi


#Creating a group with the service name
GROUP_ID=`curl --request POST --header "PRIVATE-TOKEN: $GITLAB_TOKEN" \
     --header "Content-Type: application/json" \
     --data '{"path": "wan_sites", "name": "wan_sites"}' \
     "$GITLAB_URL/api/v4/groups/" | jq .id`



#Creating the clients subgroup setting the parent with the service name
CLIENT_A_ID=`curl --noproxy "*" --request POST --header "PRIVATE-TOKEN: $GITLAB_TOKEN" \
     --header "Content-Type: application/json" \
     --data '{"path": "client_a", "name": "client_a", "parent_id": '"$GROUP_ID"' }' \
     "$GITLAB_URL/api/v4/groups/" | jq .id`

CLIENT_B_ID=`curl --noproxy "*" --request POST --header "PRIVATE-TOKEN: $GITLAB_TOKEN" \
     --header "Content-Type: application/json" \
     --data '{"path": "client_b", "name": "client_b", "parent_id": '"$GROUP_ID"' }' \
     "$GITLAB_URL/api/v4/groups/" | jq .id`



#Creating projects and files (yes... could have been simple git operations)
curl --noproxy "*" --request POST --header "PRIVATE-TOKEN: $GITLAB_TOKEN" \
     --header "Content-Type: application/json" \
     --data '{"name": "site_1", "namespace_id": '"$CLIENT_A_ID"' }' \
     "$GITLAB_URL/api/v4/projects/"
TEMP=`jq --arg key0 "branch" --arg value0 "master" --arg key1 "content" --arg value1 "$(cat site_1.json)"  --arg key2 "commit_message" --arg value2 "first commit" '. | .[$key0]=$value0 | .[$key1]=$value1 | .[$key2]=$value2'    <<<'{}' `
curl --noproxy "*" --request POST --header "PRIVATE-TOKEN: $GITLAB_TOKEN" \
     --header "Content-Type: application/json" \
     --data "$TEMP" \
     "$GITLAB_URL/api/v4/projects/wan_sites%2Fclient_a%2Fsite_1/repository/files/wan_site_data.json"


curl --noproxy "*" --request POST --header "PRIVATE-TOKEN: $GITLAB_TOKEN" \
     --header "Content-Type: application/json" \
     --data '{"name": "site_2", "namespace_id": '"$CLIENT_A_ID"' }' \
     "$GITLAB_URL/api/v4/projects/"
TEMP=`jq --arg key0 "branch" --arg value0 "master" --arg key1 "content" --arg value1 "$(cat site_2.json)"  --arg key2 "commit_message" --arg value2 "first commit" '. | .[$key0]=$value0 | .[$key1]=$value1 | .[$key2]=$value2'    <<<'{}' `
curl --noproxy "*" --request POST --header "PRIVATE-TOKEN: $GITLAB_TOKEN" \
     --header "Content-Type: application/json" \
     --data "$TEMP" \
     "$GITLAB_URL/api/v4/projects/wan_sites%2Fclient_a%2Fsite_2/repository/files/wan_site_data.json"


curl --noproxy "*" --request POST --header "PRIVATE-TOKEN: $GITLAB_TOKEN" \
     --header "Content-Type: application/json" \
     --data '{"name": "site_3", "namespace_id": '"$CLIENT_B_ID"' }' \
     "$GITLAB_URL/api/v4/projects/"
TEMP=`jq --arg key0 "branch" --arg value0 "master" --arg key1 "content" --arg value1 "$(cat site_3.json)"  --arg key2 "commit_message" --arg value2 "first commit" '. | .[$key0]=$value0 | .[$key1]=$value1 | .[$key2]=$value2'    <<<'{}' `
curl --noproxy "*" --request POST --header "PRIVATE-TOKEN: $GITLAB_TOKEN" \
     --header "Content-Type: application/json" \
     --data "$TEMP" \
     "$GITLAB_URL/api/v4/projects/wan_sites%2Fclient_b%2Fsite_3/repository/files/wan_site_data.json"


curl --noproxy "*" --request POST --header "PRIVATE-TOKEN: $GITLAB_TOKEN" \
     --header "Content-Type: application/json" \
     --data '{"name": "site_4", "namespace_id": '"$CLIENT_B_ID"' }' \
     "$GITLAB_URL/api/v4/projects/"
TEMP=`jq --arg key0 "branch" --arg value0 "master" --arg key1 "content" --arg value1 "$(cat site_4.json)"  --arg key2 "commit_message" --arg value2 "first commit" '. | .[$key0]=$value0 | .[$key1]=$value1 | .[$key2]=$value2'    <<<'{}' `
curl --noproxy "*" --request POST --header "PRIVATE-TOKEN: $GITLAB_TOKEN" \
     --header "Content-Type: application/json" \
     --data "$TEMP" \
     "$GITLAB_URL/api/v4/projects/wan_sites%2Fclient_b%2Fsite_4/repository/files/wan_site_data.json"

