#!/bin/bash

echo "#############################################################"
echo "#############################################################"
echo "### This script will create and configure hashicorp vault ###"
echo "#############################################################"
echo "#############################################################"
echo "After executed you should be able to login on vault1 using URL http://[host_ip]:8200 and vault2 using URL http://[host_ip]:9200. Use Token authentication 'fullstackautomation-root-token'"
echo "You should also be able to use the same token 'fullstackautomation-root-token' to consumes vaults API via HTTP"
echo ""
echo "*** Please, consider that you must wait around 2 minutes before everything is ok***"
echo ""
echo ""
docker-compose up -d
cd scripts
/bin/bash ./config_vaults.sh