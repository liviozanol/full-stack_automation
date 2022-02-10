#!/bin/bash

SLEEP_TIME="420" #time to wait so gitlab is up. Could be a curl and a while waiting for login page, but I'm lazy right now.
USERNAME="fullstackautomation" #username to create on gitlab
PASSWORD="fullstackautomation" #password
TOKEN="fullstack-automation" #personal auth token. must be 20 character long

echo "Sleeping for $SLEEP_TIME seconds waiting for gitlab to be up"

sleep $SLEEP_TIME


echo "Starting to create admin user $USERNAME"
#Creates a new user on gitlab
gitlab-rails console <<< "
user = User.create();
user.name = '$USERNAME';
user.username = '$USERNAME';
user.password = '$PASSWORD';
user.confirmed_at = '01/01/2000';
user.admin = true;
user.email = '$USERNAME@full-stack-automation.com';
user.save!;
puts 'User created';

token = user.personal_access_tokens.create(scopes: [:api], name: 'Automation token');
token.set_token('$TOKEN');
token.save!;
puts 'Token created';
"
