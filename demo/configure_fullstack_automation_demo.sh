#!/bin/bash
SCRIPT_DIR="$( cd -- "$( dirname -- "${BASH_SOURCE[0]}" )" &> /dev/null && pwd )"
echo "***********************************************************"
echo "***********************************************************"
echo "This is the main script for configuration of full-stack automation demo."
echo "It will call subscripts to install each element of the archtecture."
echo "You can pass arguments to the script so it doesn't ask for user input."
echo "***********************************************************"
echo "***********************************************************"

cd $SCRIPT_DIR/gitlab
/bin/bash config_gitlab.sh
echo ""
echo ""
echo ""


cd $SCRIPT_DIR/awx
/bin/bash import_files_on_gitlab.sh
echo ""
echo ""
echo ""

/bin/bash configure_awx.sh
echo ""
echo ""
echo ""

cd $SCRIPT_DIR/gitlab-ci
/bin/bash configure_gitlab_runner.sh
echo ""
echo ""
echo ""

cd $SCRIPT_DIR/api
/bin/bash import_api_files_on_gitlab_and_config_runner.sh
echo ""
echo ""
echo ""

cd $SCRIPT_DIR/bastion
/bin/bash import_bastion_files_on_gitlab.sh
echo ""
echo ""
echo ""

cd $SCRIPT_DIR/fullstack-ui
/bin/bash import_ui_files_on_gitlab.sh
echo ""
echo ""
echo ""
