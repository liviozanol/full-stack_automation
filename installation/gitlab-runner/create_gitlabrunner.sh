#!/bin/bash
echo "#############################################################"
echo "#############################################################"
echo "#### This script will create and configure gitlab-runner ####"
echo "#############################################################"
echo "#############################################################"
echo "Cloning repository and changing some default/not set passwords ans secrets"
docker run -d --name gitlab-runner --restart always \
    --privileged \
    -v /var/run/docker.sock:/var/run/docker.sock \
	-v /srv/gitlab-runner:/etc/gitlab-runner:Z \
    gitlab/gitlab-runner:alpine3.14-v14.7.0

echo ""
echo ""
echo ""
