#!/bin/bash
SCRIPT_DIR="$( cd -- "$( dirname -- "${BASH_SOURCE[0]}" )" &> /dev/null && pwd )"

COMMANDS=( "docker-compose" "docker" "jq" "ansible" "python" "openssl" "make" )
NOT_FOUND_COMMANDS=()


for cmd in ${COMMANDS[@]}; do
    if ! command -v $cmd &> /dev/null
    then
        NOT_FOUND_COMMANDS+=( "$cmd" )
    fi
done

if [ ${#NOT_FOUND_COMMANDS[@]} -ne 0 ]; then
    echo "Required commands: '${NOT_FOUND_COMMANDS[*]}' not found. Please install them."
    exit
fi



echo "***********************************************************"
echo "***********************************************************"
echo "This is the main script for full-stack automation instalation."
echo "It will call subscripts to install each element of the archtecture."
echo "***********************************************************"
echo "***********************************************************"


INSTALL_GITLAB=""
if [ $# -ne 0 ]; then
    INSTALL_GITLAB=$1
fi


if [ "$INSTALL_GITLAB" == "" ]; then
    read -p "Want to install gitlab ([y]/n)? Answer 'no' if you would like to use an existing one: " INSTALL_GITLAB
fi


cd $SCRIPT_DIR/awx
/bin/bash create_awx.sh
echo ""
echo ""
echo ""

cd $SCRIPT_DIR/vault
/bin/bash create_vaults.sh
echo ""
echo ""
echo ""

cd $SCRIPT_DIR/gitlab-runner
/bin/bash create_gitlabrunner.sh
echo ""
echo ""
echo ""


if [ "$INSTALL_GITLAB" == "" ] || [ "$INSTALL_GITLAB" == "y" ] || [ "$INSTALL_GITLAB" == "Y" ] || [ "$INSTALL_GITLAB" == "yes" ] || [ "$INSTALL_GITLAB" == "YES" ] || [ "$INSTALL_GITLAB" == "Yes" ]; then
    echo ""
    echo ""
    echo ""
    cd $SCRIPT_DIR/gitlab
    /bin/bash create_gitlab.sh
#else
#    read -p "Enter gitlab full URL (i.e. https://gitlab.com/my_full-auto_stack)." GITLAB_URL
#    echo ""
#    echo ""
#    echo ""
fi