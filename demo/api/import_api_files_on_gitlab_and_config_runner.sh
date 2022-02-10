#!/bin/bash
GITLAB_URL="http://172.17.0.1:10000/"
if [ $# -ne 0 ]; then
    GITLAB_URL="$1"
fi

GITLAB_TOKEN="fullstack-automation"
if [ $# -ge 2 ]; then
    GITLAB_TOKEN="$2"
fi

VAULT_TWO_URL="http://172.17.0.1:9200"
if [ $# -ge 3 ]; then
    VAULT_TWO_URL="$3"
fi

VAULT_TWO_TOKEN="fullstackautomation-root-token-vault2"
if [ $# -ge 4 ]; then
    VAULT_TWO_TOKEN="$4"
fi


#Creating a group to store API, Bastion and UI Files
GROUP_ID=`curl --request POST --header "PRIVATE-TOKEN: $GITLAB_TOKEN" \
     --header "Content-Type: application/json" \
     --data '{"path": "api_ui", "name": "api_ui"}' \
     "$GITLAB_URL/api/v4/groups/" | jq .id`
echo $GROUP_ID > ./tmp_group_id.tmp

#Creating project
PROJECT_ID=`curl --noproxy "*" --request POST --header "PRIVATE-TOKEN: $GITLAB_TOKEN" \
     --header "Content-Type: application/json" \
     --data '{"name": "api", "namespace_id": '"$GROUP_ID"' }' \
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
git push --set-upstream http://gitlab-ci-token:fullstack-automation@127.0.0.1:10000/api_ui/api master







#Creating vars with VAULT URL
curl --noproxy "*" -sk --request POST --header "PRIVATE-TOKEN: $GITLAB_TOKEN" --header "Content-Type: application/json" $GITLAB_URL/api/v4/groups/api_ui/variables --data '{"key": "VAULT_TWO_URL", "value": "'"$VAULT_TWO_URL"'"}'
echo ""
sleep 2

#Creating vars with VAULT TOKEN
curl --noproxy "*" -sk --request POST --header "PRIVATE-TOKEN: $GITLAB_TOKEN" --header "Content-Type: application/json" $GITLAB_URL/api/v4/groups/api_ui/variables --data '{"key": "VAULT_TWO_TOKEN", "value": "'"$VAULT_TWO_TOKEN"'", "masked":true}'
echo ""
sleep 2

#Creating vars with GITLAB_URL
curl --noproxy "*" -sk --request POST --header "PRIVATE-TOKEN: $GITLAB_TOKEN" --header "Content-Type: application/json" $GITLAB_URL/api/v4/groups/api_ui/variables --data '{"key": "GITLAB_URL", "value": "'"$GITLAB_URL"'", "masked":true}'
echo ""
sleep 2

#Getting register token from gitlab
RUNNER_REGISTRATION_TOKEN=`curl --noproxy "*" -sk --request POST --header "PRIVATE-TOKEN: $GITLAB_TOKEN" --header "Content-Type: application/json" $GITLAB_URL/api/v4/groups/api_ui/runners/reset_registration_token | jq -r .token`
if [ $# -ge 5 ]; then
    RUNNER_REGISTRATION_TOKEN="$5"
fi


#configuring Runner
#configuring Runner
#configuring Runner
docker exec -it gitlab-runner \
  gitlab-runner register \
  --non-interactive \
  --executor "docker" \
  --docker-image alpine:latest \
  --url "$GITLAB_URL" \
  --clone-url "$GITLAB_URL"\
  --registration-token "$RUNNER_REGISTRATION_TOKEN" \
  --docker-privileged \
  --docker-volumes "/var/run/docker.sock:/var/run/docker.sock"
echo ""
sleep 2

