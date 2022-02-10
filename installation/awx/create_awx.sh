#!/bin/bash
SLEEP_TIME="420"
AWX_ADMIN_USER="admin"
AWX_ADMIN_PASSWORD="awx-fullstackautomationpass"
AWX_ADDRESS_PORT="127.0.0.1:8043"
AWX_URL="https://$AWX_ADMIN_USER:$AWX_ADMIN_PASSWORD@$AWX_ADDRESS_PORT"

echo "#############################################################"
echo "#############################################################"
echo "######## This script will create and configure AWX ##########"
echo "#############################################################"
echo "#############################################################"
echo "After executed you should be able login to web ui (https://[HOST_IP]:8043) using user 'admin' and password '$AWX_ADMIN_PASSWORD'."
echo ""
echo ""


echo "Cloning repository and changing some default/not set passwords ans secrets"
git clone -b 19.5.0 https://github.com/ansible/awx.git
cd awx
sed -i 's/# pg_password=""/pg_password="fullstack_automation_pg"/g;s/# broadcast_websocket_secret=""/broadcast_websocket_secret="fullstack_automation_broadcast_websocket"/g;s/# secret_key=""/secret_key="fullstack_automation_secret"/g' tools/docker-compose/inventory


echo ""
echo ""
echo ""
echo "***BUG FIX SINCE CENTOS 8 WENT EOL.... Red Hat...***"
echo "***BUG FIX SINCE CENTOS 8 WENT EOL.... Red Hat...***"
echo "***BUG FIX SINCE CENTOS 8 WENT EOL.... Red Hat...***"
echo "changing centos:8 to centos:stream8"
sed -i 's/centos:8/centos:stream8/' tools/ansible/roles/dockerfile/templates/Dockerfile.j2
echo "***BUG FIX SINCE CENTOS 8 WENT EOL.... Red Hat...***"
echo "***BUG FIX SINCE CENTOS 8 WENT EOL.... Red Hat...***"
echo "***BUG FIX SINCE CENTOS 8 WENT EOL.... Red Hat...***"
echo ""
echo ""
echo ""

echo ""
echo ""
echo ""
echo "***ANOTHER BUG FIX... USE /etc/hostname TO GET HOSTNAME INSTEAD OF SHELL 'hostname' since it may (and IS) unavailable at container ***"
echo "***ANOTHER BUG FIX... USE /etc/hostname TO GET HOSTNAME INSTEAD OF SHELL 'hostname' since it may (and IS) unavailable at container ***"
echo "***ANOTHER BUG FIX... USE /etc/hostname TO GET HOSTNAME INSTEAD OF SHELL 'hostname' since it may (and IS) unavailable at container ***"
echo "changing Makefile"
sed -i 's/shell hostname/shell cat \/etc\/hostname/' Makefile
echo "***ANOTHER BUG FIX... USE /etc/hostname TO GET HOSTNAME INSTEAD OF SHELL 'hostname' since it may (and IS) unavailable at container ***"
echo "***ANOTHER BUG FIX... USE /etc/hostname TO GET HOSTNAME INSTEAD OF SHELL 'hostname' since it may (and IS) unavailable at container ***"
echo "***ANOTHER BUG FIX... USE /etc/hostname TO GET HOSTNAME INSTEAD OF SHELL 'hostname' since it may (and IS) unavailable at container ***"
echo ""
echo ""
echo ""

echo "Adding restart always to docker-compose file"
sed -i 's/image:.*/&\n    restart: always/' tools/docker-compose/ansible/roles/sources/templates/docker-compose.yml.j2
echo ""
echo ""
echo ""

echo ""
echo "Building the image"
EXECUTION_NODE_COUNT=1 COMPOSE_TAG=release_4.1 make docker-compose-build
echo ""
echo ""
echo ""

echo "Running AWX"
EXECUTION_NODE_COUNT=1 COMPOSE_TAG=release_4.1 COMPOSE_UP_OPTS=-d make docker-compose
echo ""
echo ""
echo ""

echo "***Sleeping for $SLEEP_TIME seconds to wait AWX to be fully running***"
sleep $SLEEP_TIME
echo ""
echo ""
echo ""

echo "Enabling WEB UI (not required but good for troubleshooting)"
docker exec tools_awx_1 make clean-ui ui-devel
echo ""
echo ""
echo ""

echo "Changing default admin password to $AWX_ADMIN_PASSWORD"
docker exec -it tools_awx_1 bash -c "awx-manage update_password --username=admin --password=$AWX_ADMIN_PASSWORD"
echo ""
echo ""
echo ""
sleep 15

echo "Creating an organization that will be used to further commands"
AWX_ORG_ID=`curl -sk --request POST $AWX_URL/api/v2/organizations/ -H "Content-Type: application/json" --data '{"description": "full stack organization", "name": "FULLSTACK_INC"}' | jq .id`
echo ""
echo ""
echo ""
sleep 5

echo "Adding Default Galaxy Credential to Organization. (Needed to install custom collections from ansible galaxy)"
curl -sk --request POST $AWX_URL/api/v2/organizations/$AWX_ORG_ID/galaxy_credentials/ -H "Content-Type: application/json" --data '{"id": 2}' | jq .id
echo ""
echo ""
echo ""
sleep 5

echo "Creating a user that will be used by GITLAB-CI to start and monitor jobs/playbooks"
AWX_USER_ID=`curl -sk --request POST $AWX_URL/api/v2/organizations/$AWX_ORG_ID/users/ -H "Content-Type: application/json" --data '{"email": "user@fullstackapi.io", "first_name": "fullstack", "is_superuser": false, "last_name": "api", "password": "fullstackapi_pass", "username": "fullstackapi" }' | jq .id`
echo ""
echo ""
echo ""
sleep 5

echo "Creating a credential type to store harshicorp vault token so it can be used later to request secrets. You could try to use the specific harshicorp vault credential type that AWX already has, but we'll be using a custom one"
AWX_VAULT_CREDENTIAL_TYPE=`curl -sk --request POST $AWX_URL/api/v2/credential_types/ -H "Content-Type: application/json" --data '{"name": "Custom Vault Cred Type","description": "Custom credential type to store vault token","kind": "cloud","inputs": {	"fields": [	{"id": "vault_server","type": "string","label": "URL to Vault Server (i.e: http://127.0.0.1:5555/)"	},{	"id": "vault_token","type": "string","label": "Vault token","secret": true}],"required": ["vault_server","vault_token"]},"injectors": {	"extra_vars": {	"vault_server": "{{ vault_server }}",	"vault_token": "{{ vault_token }}"}}}' | jq .id`
echo ""
echo ""
echo ""
sleep 5

echo "Creating a credential to store vault token and url, using the credential type just created"
AWX_VAULT_CREDENTIAL=`curl -sk --request POST $AWX_URL/api/v2/organizations/$AWX_ORG_ID/credentials/ -H "Content-Type: application/json" --data "{\"credential_type\": $AWX_VAULT_CREDENTIAL_TYPE,\"description\": \"vault credential\", \"inputs\":{\"vault_server\":\"http://127.0.0.1:9200\",\"vault_token\":\"fullstackautomation-root-token-vault2\"}, \"name\": \"vault_credential\"}" | jq .id`
echo ""
echo ""
echo ""

echo "AWX INSTALLED"