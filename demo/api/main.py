import os
import json

from typing import Optional
from fastapi import Depends, FastAPI, Request
from fastapi.middleware.cors import CORSMiddleware

from fastapi.exceptions import RequestValidationError
from fastapi.responses import PlainTextResponse
from starlette.exceptions import HTTPException as StarletteHTTPException

from check_permissions import *
from wan_api_functions import *

#TODO: CRIAR TOKEN NO AWX PARA USO DA API
#http://127.0.0.1:8000/docs
#curl --user client_a_user:client_a_user 127.0.0.1:8000/wan_sites | jq
#curl --user client_a_user:client_a_user 127.0.0.1:8000/wan_sites/site_1 | jq
#curl --user client_a_user:client_a_user 127.0.0.1:8000/wan_sites/site_1 -X PUT --data @demo/api/update_test_files/site_1.json
#curl --user client_a_user:client_a_user 127.0.0.1:8000/wan_sites/site_1/jobs?number_of_jobs=10 | jq



##python3 -m uvicorn main:app --reload
#export FULLSTACK_AUTO_GITLAB_URL="http://192.168.0.10:10000"
#export FULLSTACK_AUTO_GITLAB_TOKEN="fullstack-automation"
#export FULLSTACK_AUTO_VAULT_URL="http://192.168.0.10:9200"
#export FULLSTACK_AUTO_VAULT_TOKEN="fullstackautomation-root-token-vault2"
gitlab_url   = os.environ['FULLSTACK_AUTO_GITLAB_URL']
gitlab_token = os.environ['FULLSTACK_AUTO_GITLAB_TOKEN']
vault_url    = os.environ['FULLSTACK_AUTO_VAULT_URL']
vault_token  = os.environ['FULLSTACK_AUTO_VAULT_TOKEN']



app = FastAPI()

origins = ["*"]
app.add_middleware(
    CORSMiddleware,
    allow_origins=origins,
    allow_credentials=True,
    allow_methods=["*"],
    allow_headers=["*"],
)

#Used to customize error message, instead of returning 'detail' field, return 'message'
custom_error = {} 
@app.exception_handler(StarletteHTTPException)
async def http_exception_handler(request, exc):
    custom_error['message'] = exc.detail
    return PlainTextResponse(str(json.dumps(custom_error)), status_code=exc.status_code)
@app.exception_handler(RequestValidationError)
async def validation_exception_handler(request, exc):
    custom_error['message'] = exc.detail
    return PlainTextResponse(str(exc), status_code=exc.status_code)


# All requests are previous validate for HTTP Basic Authentication using validate_user_auth_and_get_info. It queries Vault for user/pass and get user tenant(s) from Vault.

# List all sites.
@app.get("/wan_sites")
async def root(user: str = Depends(validate_user_auth_and_get_info)):
    try:
        list_of_wan_sites_appended = []
        for tenant in user['tenants']:
            list_of_wan_sites = get_all_wan_sites_for_tenant(tenant,gitlab_url,gitlab_token)
            for site in list_of_wan_sites:
                list_of_wan_sites_appended.append(site)
            
    except Exception as e:
        raise HTTPException(status_code=status.HTTP_500_INTERNAL_SERVER_ERROR,detail=str(e)) #In Production, don't pass your internal errors, send filtered messages

    return list_of_wan_sites_appended



# Read a specific site
@app.get("/wan_sites/{siteId}")
async def root(siteId, user: str = Depends(validate_user_auth_and_get_info)):
    try:
        for tenant in user['tenants']:
            wan_site = get_one_wan_site_for_tenant(tenant,gitlab_url,gitlab_token,siteId)
            if wan_site != False:
                return wan_site

    except Exception as e:
        raise HTTPException(status_code=status.HTTP_500_INTERNAL_SERVER_ERROR,detail=str(e)) #In Production, don't pass your internal errors, send filtered messages
    # Default response is ID not found
    return HTTPException(status_code=status.HTTP_404_NOT_FOUND,detail="NOT FOUND")



# Update a specific site
@app.put("/wan_sites/{siteId}")
async def root(siteId, request: Request, sync: Optional[bool] = False, user: str = Depends(validate_user_auth_and_get_info)):
    try:
        for tenant in user['tenants']:
            wan_site = get_one_wan_site_for_tenant(tenant,gitlab_url,gitlab_token,siteId)
            if wan_site != False:
                #Found our site! Send Request Body to our update function
                changed_wan_site = change_wan_site_for_tenant(tenant, gitlab_url, gitlab_token, siteId, user['user'], sync, await request.json(), wan_site)
                return changed_wan_site

    except Exception as e:
        raise HTTPException(status_code=status.HTTP_500_INTERNAL_SERVER_ERROR,detail=str(e)) #In Production, don't pass your internal errors, send filtered messages
    
    # Default response is ID not found
    return HTTPException(status_code=status.HTTP_404_NOT_FOUND,detail="NOT FOUND")



# Get a list of the last 5 pipelines jobs from specific site
@app.get("/wan_sites/{siteId}/jobs")
async def root(siteId, number_of_jobs: Optional[int] = False, user: str = Depends(validate_user_auth_and_get_info)):
    try:
        for tenant in user['tenants']:
            wan_site = get_one_wan_site_for_tenant(tenant,gitlab_url,gitlab_token,siteId)
            if wan_site != False:
                if not number_of_jobs:
                    number_of_jobs = 5
                jobs = get_gitlab_pipeline_last_jobs(tenant, gitlab_url, gitlab_token, siteId, number_of_jobs)
                return jobs

    except Exception as e:
        raise HTTPException(status_code=status.HTTP_500_INTERNAL_SERVER_ERROR,detail=str(e)) #In Production, don't pass your internal errors, send filtered messages
    # Default response is ID not found
    return HTTPException(status_code=status.HTTP_404_NOT_FOUND,detail="NOT FOUND")



#Not used! Won't be able to create items
#@app.post()

#Not used! Won't be able to delete items
#@app.delete()