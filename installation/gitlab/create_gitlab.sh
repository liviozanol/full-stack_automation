#!/bin/bash

echo "#############################################################"
echo "#############################################################"
echo "####### This script will create and configure gitlab ########"
echo "#############################################################"
echo "#############################################################"
echo "After executed you should be able to login on gitlab using URL http://[host_ip]:10000 and user/pass 'fullstackautomation'"
echo "You should also be able to use the token 'fullstack-automation' to consumes gitlab API via HTTP"
echo ""
echo "*** Please, consider that you must wait around 3 minutes before everything is ok and you can use the credentials created ***"
echo ""
echo ""
docker-compose up -d
docker exec -it gitlab_fullstack_automation /bin/bash /tmp/scripts/create_user_and_access_token.sh
