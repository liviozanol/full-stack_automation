#!/bin/bash
VAULT_TOKEN="fullstackautomation-root-token" #token with permissions to create secrets on vault 1
SLEEP_TIME="60" #time to wait so vault is up. Could be a curl and a while waiting for login page, but I'm lazy right now.
VAULT_TOKEN2="fullstackautomation-root-token-vault2" #token with permissions to create secrets on vault 2

echo "Sleeping for $SLEEP_TIME seconds waiting for vault to be up"
sleep $SLEEP_TIME


echo "*** Creating Router Secret on Vault 1 ***"
curl --noproxy '*' --header "X-Vault-Token: $VAULT_TOKEN" \
    --request POST \
    --data @vault1_router_secret.json \
    http://127.0.0.1:8200/v1/secret/data/router_secret
sleep 1

echo "*** Creating Gitlab Secret on Vault 2 ***"
curl --noproxy '*' --header "X-Vault-Token: $VAULT_TOKEN2" \
    --request POST \
    --data @vault2_gitlab_secret.json \
    http://127.0.0.1:9200/v1/secret/data/gitlab_secret
sleep 1

echo "*** Creating AWX Secret on Vault 2 ***"
curl --noproxy '*' --header "X-Vault-Token: $VAULT_TOKEN2" \
    --request POST \
    --data @vault2_awx_secret.json \
    http://127.0.0.1:9200/v1/secret/data/awx_secret
sleep 1


echo "*** Creating Client_A API User Secret on Vault 2 ***"
curl --noproxy '*' --header "X-Vault-Token: $VAULT_TOKEN2" \
    --request POST \
    --data @vault2_api_client_a_secret.json \
    http://127.0.0.1:9200/v1/secret/data/client_a_user
sleep 1

echo "*** Creating Client_B API User Secret on Vault 2 ***"
curl --noproxy '*' --header "X-Vault-Token: $VAULT_TOKEN2" \
    --request POST \
    --data @vault2_api_client_b_secret.json \
    http://127.0.0.1:9200/v1/secret/data/client_b_user
sleep 1

echo "*** Creating Admin API User Secret on Vault 2 ***"
curl --noproxy '*' --header "X-Vault-Token: $VAULT_TOKEN2" \
    --request POST \
    --data @vault2_api_admin_secret.json \
    http://127.0.0.1:9200/v1/secret/data/admin_user
sleep 1


