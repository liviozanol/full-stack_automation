#!/bin/bash
GITLAB_URL="http://127.0.0.1:10000"
if [ $# -ne 0 ]; then
    GITLAB_URL="$1"
fi

GITLAB_TOKEN="fullstack-automation"
if [ $# -eq 2 ]; then
    GITLAB_TOKEN="$2"
fi


#Creating a group to store AWX related files
GROUP_ID=`curl --request POST --header "PRIVATE-TOKEN: $GITLAB_TOKEN" \
     --header "Content-Type: application/json" \
     --data '{"path": "awx", "name": "awx"}' \
     "$GITLAB_URL/api/v4/groups/" | jq .id`

#Creating project
PROJECT_ID=`curl --noproxy "*" --request POST --header "PRIVATE-TOKEN: $GITLAB_TOKEN" \
     --header "Content-Type: application/json" \
     --data '{"name": "wan_site_automation", "namespace_id": '"$GROUP_ID"' }' \
     "$GITLAB_URL/api/v4/projects/" | jq .id`

#Creating a deploy token on the project
GITLAB_DEPLOY_TOKEN=`curl --noproxy "*" --request POST --header "PRIVATE-TOKEN: $GITLAB_TOKEN" \
     --header "Content-Type: application/json" \
     --data '{"name": "awx_deploy_token", "username": "awx_deploy_token", "scopes": ["read_repository"]}' \
     "$GITLAB_URL/api/v4/projects/awx%2Fwan_site_automation/deploy_tokens" | jq -r .token`
echo $GITLAB_DEPLOY_TOKEN > ./tmp_token_file.tmp

#Submiting files (yes... could have been a simple git operation)
TEMP=`jq --arg key0 "branch" --arg value0 "master" --arg key1 "content" --arg value1 "$(cat awx_files/inventory.yml)"  --arg key2 "commit_message" --arg value2 "adding main playbook" '. | .[$key0]=$value0 | .[$key1]=$value1 | .[$key2]=$value2'    <<<'{}' `
curl --noproxy "*" --request POST --header "PRIVATE-TOKEN: $GITLAB_TOKEN" \
     --header "Content-Type: application/json" \
     --data "$TEMP" \
     "$GITLAB_URL/api/v4/projects/awx%2Fwan_site_automation/repository/files/inventory.yml"

TEMP=`jq --arg key0 "branch" --arg value0 "master" --arg key1 "content" --arg value1 "$(cat awx_files/wan_automation_principal.yml)"  --arg key2 "commit_message" --arg value2 "adding main playbook" '. | .[$key0]=$value0 | .[$key1]=$value1 | .[$key2]=$value2'    <<<'{}' `
curl --noproxy "*" --request POST --header "PRIVATE-TOKEN: $GITLAB_TOKEN" \
     --header "Content-Type: application/json" \
     --data "$TEMP" \
     "$GITLAB_URL/api/v4/projects/awx%2Fwan_site_automation/repository/files/wan_automation_principal.yml"

TEMP=`jq --arg key0 "branch" --arg value0 "master" --arg key1 "content" --arg value1 "$(cat awx_files/ios_playbook.yml)"  --arg key2 "commit_message" --arg value2 "adding main playbook" '. | .[$key0]=$value0 | .[$key1]=$value1 | .[$key2]=$value2'    <<<'{}' `
curl --noproxy "*" --request POST --header "PRIVATE-TOKEN: $GITLAB_TOKEN" \
     --header "Content-Type: application/json" \
     --data "$TEMP" \
     "$GITLAB_URL/api/v4/projects/awx%2Fwan_site_automation/repository/files/ios_playbook.yml"

TEMP=`jq --arg key0 "branch" --arg value0 "master" --arg key1 "content" --arg value1 "$(cat awx_files/ios_template.j2)"  --arg key2 "commit_message" --arg value2 "adding main playbook" '. | .[$key0]=$value0 | .[$key1]=$value1 | .[$key2]=$value2'    <<<'{}' `
curl --noproxy "*" --request POST --header "PRIVATE-TOKEN: $GITLAB_TOKEN" \
     --header "Content-Type: application/json" \
     --data "$TEMP" \
     "$GITLAB_URL/api/v4/projects/awx%2Fwan_site_automation/repository/files/ios_template.j2"

TEMP=`jq --arg key0 "branch" --arg value0 "master" --arg key1 "content" --arg value1 "$(cat awx_files/start.yml)"  --arg key2 "commit_message" --arg value2 "adding main playbook" '. | .[$key0]=$value0 | .[$key1]=$value1 | .[$key2]=$value2'    <<<'{}' `
curl --noproxy "*" --request POST --header "PRIVATE-TOKEN: $GITLAB_TOKEN" \
     --header "Content-Type: application/json" \
     --data "$TEMP" \
     "$GITLAB_URL/api/v4/projects/awx%2Fwan_site_automation/repository/files/start.yml"

TEMP=`jq --arg key0 "branch" --arg value0 "master" --arg key1 "content" --arg value1 "$(cat awx_files/collections/requirements.yml)"  --arg key2 "commit_message" --arg value2 "adding main playbook" '. | .[$key0]=$value0 | .[$key1]=$value1 | .[$key2]=$value2'    <<<'{}' `
curl --noproxy "*" --request POST --header "PRIVATE-TOKEN: $GITLAB_TOKEN" \
     --header "Content-Type: application/json" \
     --data "$TEMP" \
     "$GITLAB_URL/api/v4/projects/awx%2Fwan_site_automation/repository/files/collections%2Frequirements.yml"

