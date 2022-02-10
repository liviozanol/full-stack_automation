import requests
import re
import os

from fastapi import FastAPI, Depends, HTTPException, status 
from fastapi.security import HTTPBasic, HTTPBasicCredentials

gitlab_url   = os.environ['FULLSTACK_AUTO_GITLAB_URL']
gitlab_token = os.environ['FULLSTACK_AUTO_GITLAB_TOKEN']
vault_url    = os.environ['FULLSTACK_AUTO_VAULT_URL']
vault_token  = os.environ['FULLSTACK_AUTO_VAULT_TOKEN']

security = HTTPBasic()

def get_secret_from_vault(secret_path):
    headers = {'X-Vault-Token': vault_token}
    url = vault_url+"/v1/secret/data/"+secret_path
    try:
        # Making HTTP request
        response = requests.get(url, headers=headers)

        # If content is empy there is some problem requesting the server
        if (response.content is None):
            raise HTTPException(status_code=status.HTTP_500_INTERNAL_SERVER_ERROR,detail='Reponse error from auth server.')
        
        # If data is not present on json response, user probably doesn't exists
        response_json=response.json()
        if ('data' not in response_json):
            raise HTTPException(status_code=status.HTTP_401_UNAUTHORIZED,detail='User not found (on production you should mask better this message better to avoid username mining).')

        return response_json['data']['data']
        
    except requests.exceptions.RequestException as e:
        print("A")
        raise HTTPException(status_code=status.HTTP_500_INTERNAL_SERVER_ERROR,detail='Could not contact auth server or other error requesting auth server.')


async def validate_user_auth_and_get_info(credentials: HTTPBasicCredentials = Depends(security)):
    #Sanitize received data and check for regex match
    username = credentials.username
    password = credentials.password
    username_regex_allowed_chars = '^[a-zA-Z0-9_\-]+$'

    # Check if username is not defined
    if not username:
        raise HTTPException(status_code=status.HTTP_401_UNAUTHORIZED,detail='"username" not defined.',headers={"WWW-Authenticate": "Basic"})

    # Check if username matches validation regex
    if not re.match(username_regex_allowed_chars, username):
        raise HTTPException(status_code=status.HTTP_401_UNAUTHORIZED,detail='"username" does not match required regex: {username_regex_allowed_chars}.',headers={"WWW-Authenticate": "Basic"})
    
    # Send to function that will query user on vault
    secret_from_vault = get_secret_from_vault(username)
    
    if ('pass' not in secret_from_vault):
        raise HTTPException(status_code=status.HTTP_401_UNAUTHORIZED,detail='Password field not found on auth server response (on production you should mask better this message better).')
    
    # Check if passwords match
    if (password != secret_from_vault['pass']):
        raise HTTPException(status_code=status.HTTP_401_UNAUTHORIZED,detail='Password for provided user does not match (on production you should mask better this message better).')

    # Everything ok!
    return secret_from_vault
