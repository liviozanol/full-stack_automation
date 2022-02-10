#!/bin/bash
AWX_ADDRESS_PORT="127.0.0.1:8043"
if [ $# -ne 0 ]; then
    AWX_URL="$1"
fi

AWX_USER="admin"
if [ $# -ge 2 ]; then
    AWX_USER="$2"
fi

AWX_PASS="awx-fullstackautomationpass"
if [ $# -ge 3 ]; then
    AWX_PASS="$3"
fi
AWX_URL="https://$AWX_USER:$AWX_PASS@$AWX_ADDRESS_PORT"


GITLAB_PROJECT_URL="http://172.17.0.1:10000/awx/wan_site_automation"
if [ $# -ge 4 ]; then
    GITLAB_PROJECT_URL="$4"
fi

GITLAB_DEPLOY_TOKEN_USER="awx_deploy_token"
if [ $# -ge 5 ]; then
    GITLAB_DEPLOY_TOKEN_USER="$5"
fi

GITLAB_DEPLOY_TOKEN_PASS=`cat tmp_token_file.tmp`
if [ $# -ge 6 ]; then
    GITLAB_DEPLOY_TOKEN_PASS="$6"
fi


AWX_ORG_ID=`curl -sk $AWX_URL/api/v2/organizations/ | jq '.results[] | select(.name=="FULLSTACK_INC") | .id'`

echo "Creating a credential that will store gitlab deploy token so AWX can load inventories, playbooks and other files stored there"
AWX_GITLAB_CREDENTIAL_ID=`curl -sk --request POST $AWX_URL/api/v2/organizations/$AWX_ORG_ID/credentials/ -H "Content-Type: application/json" --data '{"credential_type": 2,"description": "git lab credential", "inputs":{"username":"'"$GITLAB_DEPLOY_TOKEN_USER"'","password":"'$GITLAB_DEPLOY_TOKEN_PASS'"}, "name": "gitlab_token"}' | jq .id`
echo ""
echo ""
echo ""
sleep 5

echo "Creating AWX Project"
AWX_PROJECT_ID=`curl -sk --request POST $AWX_URL/api/v2/projects/ -H "Content-Type: application/json" --data '{"description": "WAN Sites Automation Project", "name": "wan_automation", "organization":'"$AWX_ORG_ID"', "scm_type": "git", "scm_url": "'"$GITLAB_PROJECT_URL"'", "credential":'"$AWX_GITLAB_CREDENTIAL_ID"'}' | jq .id`
echo ""
echo ""
echo ""
echo "Sleeping 180 seconds to project update..."
sleep 180
echo ""

echo "Creating Inventory"
AWX_INVENTORY_ID=`curl -sk --request POST $AWX_URL/api/v2/inventories/ -H "Content-Type: application/json" --data '{"description": "WAN Sites Automation Inventory", "name": "wan_automation_inventory", "organization":'"$AWX_ORG_ID"' }' | jq .id`
echo ""
echo ""
echo ""
sleep 5

echo "Setting Inventory Source to use the Project"
AWX_INVENTORY_SOURCE_ID=`curl -sk --request POST $AWX_URL/api/v2/inventories/$AWX_INVENTORY_ID/inventory_sources/ -H "Content-Type: application/json" --data '{"description": "WAN Sites Automation Inventory Source", "name": "wan_automation_inventory_source", "source": "scm", "source_project": '"$AWX_PROJECT_ID"', "update_on_launch":false }' | jq .id`
echo ""
echo ""
echo ""
sleep 5

echo "Updating inventory source"
AWX_INVENTORY_SOURCE_ID=`curl -sk --request POST $AWX_URL/api/v2/inventory_sources/$AWX_INVENTORY_SOURCE_ID/update/ -H "Content-Type: application/json" --data '{}' | jq .id`
echo ""
echo ""
echo ""
sleep 10

echo "Creating Job Template for dumb start task"
AWX_START_JOB_TEMPLATE_ID=`curl -sk --request POST  $AWX_URL/api/v2/job_templates/ -H "Content-Type: application/json" --data '{"description": "WAN Sites Automation Job Template dumb", "name": "wan_automation_job_template_dumb", "organization":'"$AWX_ORG_ID"', "project":'"$AWX_PROJECT_ID"', "inventory":'"$AWX_INVENTORY_ID"', "ask_variables_on_launch": true, "playbook":"start.yml"}' | jq .id`
echo ""
echo ""
echo ""
sleep 5

echo "Creating Job Template for main task"
AWX_MAIN_JOB_TEMPLATE_ID=`curl -sk --request POST  $AWX_URL/api/v2/job_templates/ -H "Content-Type: application/json" --data '{"description": "WAN Sites Automation Job Template", "name": "wan_automation_job_template", "organization":'"$AWX_ORG_ID"', "project":'"$AWX_PROJECT_ID"', "inventory":'"$AWX_INVENTORY_ID"', "ask_variables_on_launch": true, "playbook":"wan_automation_principal.yml"}' | jq .id`
echo ""
echo ""
echo ""
sleep 5

echo "Creating Workflow Job Template"
AWX_WORKFLOW_TEMPLATE_ID=`curl -sk --request POST  $AWX_URL/api/v2/workflow_job_templates/ -H "Content-Type: application/json" --data '{"description": "WAN Sites Automation Workflow", "name": "wan_automation_workflow_template", "organization":'"$AWX_ORG_ID"', "project":'"$AWX_PROJECT_ID"', "inventory":'"$AWX_INVENTORY_ID"', "ask_variables_on_launch": true}' | jq .id`
echo ""
echo ""
echo ""
sleep 5

echo "Adding job template 1 to Workflow"
AWX_WORKFLOW_JOB_TEMPLATE_ONE_ID=`curl -sk --request POST  $AWX_URL/api/v2/workflow_job_templates/$AWX_WORKFLOW_TEMPLATE_ID/workflow_nodes/ -H "Content-Type: application/json" --data '{"unified_job_template":'"$AWX_START_JOB_TEMPLATE_ID"'}' | jq .id`
echo ""
echo ""
echo ""
sleep 5

echo "Adding job template 2 to Workflow"
AWX_WORKFLOW_JOB_TEMPLATE_TWO_ID=`curl -sk --request POST  $AWX_URL/api/v2/workflow_job_templates/$AWX_WORKFLOW_TEMPLATE_ID/workflow_nodes/ -H "Content-Type: application/json" --data '{"unified_job_template":'"$AWX_MAIN_JOB_TEMPLATE_ID"'}' | jq .id`
echo ""
echo ""
echo ""
sleep 5

echo "Linking jobs on the workflow"
AWX_WORKFLOW_JOB_TEMPLATE_LINK=`curl -sk --request POST  $AWX_URL/api/v2/workflow_job_template_nodes/$AWX_WORKFLOW_JOB_TEMPLATE_ONE_ID/success_nodes/ -H "Content-Type: application/json" --data '{"id":'"$AWX_WORKFLOW_JOB_TEMPLATE_TWO_ID"'}'`
echo ""
echo ""
echo ""
sleep 5

echo "Getting execute role id from workflow template"
AWX_WORKFLOW_EXECUTE_ROLE_ID=`curl -sk $AWX_URL/api/v2/workflow_job_templates/$AWX_WORKFLOW_TEMPLATE_ID/object_roles/ | jq '.results[] | select(.description | match("^May run.*")) | .id'`
echo ""
echo ""
echo ""
sleep 5

echo "Getting fullstackapi user id"
AWX_FULLSTACK_USER_ID=`curl -sk $AWX_URL/api/v2/users/ | jq '.results[] | select(.username == "fullstackapi") | .id'`
echo ""
echo ""
echo ""
sleep 5

echo "Assigning user fullstackapi the run role on workflow template"
AWX_ASSIGN_ROLE=`curl -sk --request POST $AWX_URL/api/v2/users/$AWX_FULLSTACK_USER_ID/roles/ -H "Content-Type: application/json" --data '{"id":'"$AWX_WORKFLOW_EXECUTE_ROLE_ID"'}'`
echo ""
echo ""
echo ""


echo "END OF AWX DEMO CONFIGURATION"