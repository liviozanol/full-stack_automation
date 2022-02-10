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

AWX_ADDRESS_PORT="172.17.0.1:8043"
if [ $# -ge 5 ]; then
    AWX_ADDRESS_PORT="$5"
fi

#Getting register token from gitlab
RUNNER_REGISTRATION_TOKEN=`curl --noproxy "*" -sk --request POST --header "PRIVATE-TOKEN: $GITLAB_TOKEN" --header "Content-Type: application/json" $GITLAB_URL/api/v4/groups/wan_sites/runners/reset_registration_token | jq -r .token`
if [ $# -ge 5 ]; then
    RUNNER_REGISTRATION_TOKEN="$5"
fi

#Uploading .gitlab-ci.yml to all projects
curl --noproxy "*" --request POST --header "PRIVATE-TOKEN: $GITLAB_TOKEN" \
--header "Content-Type: application/json" \
--data "{\"branch\": \"master\", \"content\": \""$(base64 .gitlab-ci.yml | sed ':a;N;$!ba;s/\n/\\n/g')"\", \"commit_message\": \"adding gitlab-ci\", \"encoding\": \"base64\"}" \
"$GITLAB_URL/api/v4/projects/wan_sites%2Fclient_a%2Fsite_1/repository/files/.gitlab-ci.yml"
echo ""
sleep 2

curl --noproxy "*" --request POST --header "PRIVATE-TOKEN: $GITLAB_TOKEN" \
--header "Content-Type: application/json" \
--data "{\"branch\": \"master\", \"content\": \""$(base64 .gitlab-ci.yml | sed ':a;N;$!ba;s/\n/\\n/g')"\", \"commit_message\": \"adding gitlab-ci\", \"encoding\": \"base64\"}" \
"$GITLAB_URL/api/v4/projects/wan_sites%2Fclient_a%2Fsite_2/repository/files/.gitlab-ci.yml"
echo ""
sleep 2

curl --noproxy "*" --request POST --header "PRIVATE-TOKEN: $GITLAB_TOKEN" \
--header "Content-Type: application/json" \
--data "{\"branch\": \"master\", \"content\": \""$(base64 .gitlab-ci.yml | sed ':a;N;$!ba;s/\n/\\n/g')"\", \"commit_message\": \"adding gitlab-ci\", \"encoding\": \"base64\"}" \
"$GITLAB_URL/api/v4/projects/wan_sites%2Fclient_b%2Fsite_3/repository/files/.gitlab-ci.yml"
echo ""
sleep 2

curl --noproxy "*" --request POST --header "PRIVATE-TOKEN: $GITLAB_TOKEN" \
--header "Content-Type: application/json" \
--data "{\"branch\": \"master\", \"content\": \""$(base64 .gitlab-ci.yml | sed ':a;N;$!ba;s/\n/\\n/g')"\", \"commit_message\": \"adding gitlab-ci\", \"encoding\": \"base64\"}" \
"$GITLAB_URL/api/v4/projects/wan_sites%2Fclient_b%2Fsite_4/repository/files/.gitlab-ci.yml"
echo ""
sleep 2

#configuring Runner
docker exec -it gitlab-runner \
  gitlab-runner register \
  --non-interactive \
  --executor "docker" \
  --docker-image alpine:latest \
  --url "$GITLAB_URL" \
  --clone-url "$GITLAB_URL"\
  --registration-token "$RUNNER_REGISTRATION_TOKEN" \
  --docker-volumes "/var/run/docker.sock:/var/run/docker.sock" \
  --docker-privileged
echo ""
sleep 2

#Creating vars with VAULT URL
curl --noproxy "*" -sk --request POST --header "PRIVATE-TOKEN: $GITLAB_TOKEN" --header "Content-Type: application/json" $GITLAB_URL/api/v4/groups/wan_sites/variables --data '{"key": "VAULT_TWO_URL", "value": "'"$VAULT_TWO_URL"'"}'
echo ""
sleep 2

#Creating vars with VAULT TOKEN
curl --noproxy "*" -sk --request POST --header "PRIVATE-TOKEN: $GITLAB_TOKEN" --header "Content-Type: application/json" $GITLAB_URL/api/v4/groups/wan_sites/variables --data '{"key": "VAULT_TWO_TOKEN", "value": "'"$VAULT_TWO_TOKEN"'", "masked":true}'
echo ""
sleep 2

#Creating var with AWX ADDRESS/PORT
curl --noproxy "*" -sk --request POST --header "PRIVATE-TOKEN: $GITLAB_TOKEN" --header "Content-Type: application/json" $GITLAB_URL/api/v4/groups/wan_sites/variables --data '{"key": "AWX_ADDRESS_PORT", "value": "'"$AWX_ADDRESS_PORT"'"}'

echo ""
echo "Raise concurrent jobs on gitlab-runner to 4. May be a better way to do this, but I couldn't find and don't want to create a config.toml template..."
sed -i 's/concurrent = 1/concurrent = 4/' /srv/gitlab-runner/config.toml
sleep 5
docker stop gitlab-runner && docker start gitlab-runner