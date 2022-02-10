## General Info

This repo is intended to install and/or configure full-stack automation architecture.

See posts about it on https://livio.zanol.com.br/full-stack-it-automation-part-1

Tested on Ubuntu 20.04.3 LT

## Requirements

- You need to have a network connection to the Internet.
- You need to have 8GB of FREE RAM.
- You need to have around 20 GB of disk space (if using VM).
- You need to have the following programs installed:
    - bash
    - curl
    - jq
    - openssl
    - docker (installed and running)
    - docker-compose
    - ansible
    - python3
    - pip
    - build-essential (or lsb-release/make or similar, to use 'make' to install AWX)

I recommend that you install it inside a virtual machine. You can use [virtual box](https://www.virtualbox.org/) or [Vmware Workstation](https://www.vmware.com/br/products/workstation-player.html) which I recommend between these 2.

## Information and Usage
Please, consider reading the [posts](https://livio.zanol.com.br/full-stack-it-automation-part-1) about full-stack automation before you do anything.

These shell scripts will install AWX, Gitlab, 2 vaults and Gitlab runner in docker containers on your host. Also, if you execute the demo script, it will also install 3 more containers with a bastion host (for the API), the demo API and the demo UI based on React.

After you clone the repo you can:
- Use ```sudo /bin/bash install_and_configure_demo.sh``` to Install AND configure the full-stack automation demo.
- Use ```sudo /bin/bash installation/install_fullstack_automation_demo.sh``` to only install components.
- Use ```sudo /bin/bash demo/configure_fullstack_automation_demo.sh``` to only configure the demo.
- Or use any specific script to install configure each element (awx, gitlab, vault, etc.) separated with your own customization.

After script finish (around 30 minutes) you should see 12 containers running (5 for AWX, 1 for gitlab, 2 for vaults, 1 for gitlab runner, 1 for API, 1 for bastion and 1 for UI). Maybe you need to wait some time (~ 10 minutes) so CI/CD starts the API and UI containers.

**After that you can access the UI using http://[HOST_IP] or the API using http://[HOST_IP]:10042**

## Notes

Please, consider these important informations:

- **This a DEMO and is not suitable for production**
- Docker containers are communication with each other using default docker network address on 172.17.0.1/16, you should consider changing this on production.
- We are sharing some default admin token or user/pass with our elements. On production you should create specific user/pass and token for each element and with the least privilege required.

## Default Credentials

These are the default credentials to login to each element:

- AWX (listening on port 8043):
    - user: *admin*
    - password: *awx-fullstackautomationpass*
    - fullstack user: *fullstackapi*
    - fullstack password: *fullstackapi_pass*
- Gitlab (listening on port 10000):
    - user: *fullstackautomation*
    - password: *fullstackautomation*
    - token: *fullstack-automation* (for API requests)
- Vault 1 (listening on port 8200):
    - token: *fullstackautomation-root-token*
- Vault 2 (listening on port 9200):
    - token: *fullstackautomation-root-token-vault2*
- API users/pass (listening on port 10042):
    - client_a_user/client_a_user
    - client_b_user/client_b_user
    - admin_user/admin_user  (with access for the 2 tenants)