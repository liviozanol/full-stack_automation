import re
import requests
import base64
import json
import time

from fastapi import HTTPException, status 

from netaddr import IPNetwork

#name of the service on gitlab (it's a gitlab group).
service_name = "wan_sites"





def get_all_wan_sites_for_tenant(tenant_name, gitlab_url, gitlab_token):
    """
    Get all sites for a specific client/tenant.
    It uses the tenant_name provided as a part of the path/URL to query gitlab on specific project.
    On gitlab the organization for a service will be "Service (group) -> Tenant/Client (subgroup) -> CPEs/wan sites (projects)":
        - Service Group: wan_sites
        - Tenant Subgroup: client_1
        - Each CPE/wan site Project: site_1, site_2, etc.
        - Complete project path: /wan_sites/client_1/site_1

    Parameters:
        tenant_name   (str): The name of a client/tenant.
        gitlab_url    (str): Gitlab URL
        gitlab_token  (str): Gitlab Auth/Bearer Token

    Returns:
        dict: List of all sites belonging to current client

    Raises:
        ValueError: if tenant_name is not defined or not valid
        LookupError: if tenant_name not found or backend (gitlab) server error
    """

    list_of_wan_sites = []

    # Regex with allowed chars for tenant_name
    tenant_name_regex_allowed_chars = '^[a-zA-Z0-9_\-]+$'
    # Check if tenant_name is not defined
    if not tenant_name:
        raise ValueError('"tenant_name" not defined.')
    # Check if tenant_name matches validation regex
    if not re.match(tenant_name_regex_allowed_chars, tenant_name):
        raise ValueError('"tenant_name" does not match required regex: {tenant_name_regex_allowed_chars}.')

    # Get a list of all projects (wan sites/cpes) belonging to a tenant.
    # Set URL. Remembering: each service is a group and each tenant/client is a subgroup of service. Each project is a service instance (CPE)
    request_url = gitlab_url + "/api/v4/groups/" + service_name + "%2F" + tenant_name + "/projects"

    # Make HTTP request to gitlab
    response = requests.get(request_url, headers={'PRIVATE-TOKEN': gitlab_token})

    # Check for error on gitlab response
    if response.status_code != 200:
        raise LookupError('Received Code {response.status_code} from gitlab. Full Response: "{response.content}"')

    # Decode json string to object.
    decoded_response = response.json()
    # Each client can have multiple wan sites, each wan site is a project on gitlab.
    for project in decoded_response:

        # For each project get the data file content with the structured data
        try:
            result = get_one_wan_site_for_tenant(tenant_name, gitlab_url, gitlab_token, project['name'])
        except:
            pass
        else:
            result['id'] = project['name']
            result['tenant'] = tenant_name
            list_of_wan_sites.append(result)
    return list_of_wan_sites







def get_one_wan_site_for_tenant(tenant_name, gitlab_url, gitlab_token, site_id):
    """
    Get a specific wan site for a specific client/tenant.
    It uses the tenant_name and site_id provided as a part of the path/URL to query gitlab on a specific project (a specific wan_site/CPE).

    Parameters:
        tenant_name   (str): The name of a client/tenant.
        gitlab_url    (str): Gitlab URL.
        gitlab_token  (str): Gitlab Auth/Bearer Token.
        site_id       (str): Specific WAN site ID.

    Returns:
        dict: Specific WAN site information.

    Raises:
        ValueError: if tenant_name is not defined or not valid
        LookupError: if tenant_name not found or backend (gitlab) server error
    """

    # Regex with allowed chars for tenant_name
    tenant_name_regex_allowed_chars = '^[a-zA-Z0-9_\-]+$'
    # Check if tenant_name is not defined
    if not tenant_name:
        raise ValueError('"tenant_name" not defined.')
    # Check if tenant_name matches validation regex
    if not re.match(tenant_name_regex_allowed_chars, tenant_name):
        raise ValueError('"tenant_name" does not match required regex: {tenant_name_regex_allowed_chars}.')

    site_id_regex_allowed_chars = '^[a-zA-Z0-9_\-]+$'
    # Check if site_id is not defined
    if not site_id:
        raise ValueError('"site_id" not defined.')
    # Check if site_id matches validation regex
    if not re.match(site_id_regex_allowed_chars, site_id):
        raise ValueError('"site_id" does not match required regex: {site_id_regex_allowed_chars}.')
    
    request_url = gitlab_url + "/api/v4/projects/" + service_name + "%2F" + tenant_name + "%2F" + site_id + "/repository/files/wan_site_data.json/raw?ref=master" 
    
    # Make HTTP request to gitlab
    response = requests.get(request_url, headers={'PRIVATE-TOKEN': gitlab_token})

    # Check for error on gitlab response
    if response.status_code != 200:
        return False

    # Return decoded json string to object.
    result = response.json()
    result['id'] = site_id
    result['tenant'] = tenant_name

    return result







def change_wan_site_for_tenant(tenant_name, gitlab_url, gitlab_token, site_id, username, sync, new_data, current_data):
    """
    Get a specific wan site for a specific client/tenant.
    It uses the tenant_name and site_id provided as a part of the path/URL to query gitlab on a specific project (a specific wan_site/CPE).

    Parameters:
        tenant_name   (str): The name of a client/tenant.
        gitlab_url    (str): Gitlab URL.
        gitlab_token  (str): Gitlab Auth/Bearer Token.
        site_id       (str): Specific WAN site ID.
        username      (str): Username of the user that is making the request
        sync          (bool): If user wants to for the pipeline job to be completed, this should be true.
        new_data      (dict): JSON sent by the user with modified data for WAN site
        current_data  (dict): JSON with current wan_site data

    Returns:
        dict: Specific WAN site information updated.

    Raises:
        ValueError: if any value is not validated
    """

    updated_data = validate_data_sent_by_user(current_data,new_data)
    #If we are here, data is validated! We can send it to gitlab to start our CI/CD cycle!
    #If we are here, data is validated! We can send it to gitlab to start our CI/CD cycle!
    #If we are here, data is validated! We can send it to gitlab to start our CI/CD cycle!
    
    #deleting added field by get method
    if 'id' in updated_data:
        del updated_data['id']
    if 'tenant' in updated_data:
        del updated_data['tenant']


    request_url = gitlab_url + "/api/v4/projects/" + service_name + "%2F" + tenant_name + "%2F" + site_id + "/repository/files/wan_site_data%2Ejson" 
    
    content_string_base64 = base64.b64encode(json.dumps(updated_data, indent=2).encode('ascii')) #ident=2 just to improve readability on demo
    payload = {"branch": "master", "encoding": "base64", "content": content_string_base64.decode(), "commit_message": "changed using API by user '" + username+"'"}
    
    # Make HTTP request to gitlab
    response = requests.put(request_url, headers={'PRIVATE-TOKEN': gitlab_token}, data=payload)

    if response.status_code != 200:
        raise LookupError('Received Code {response.status_code} from gitlab. Full Response: "{response.content}"')

    # Return decoded json string to object.
    if not sync:
        #inserting back id so we have and id on response
        updated_data['id'] = updated_data['site_id']
        return updated_data

    time.sleep(6) #Sleeping the time between gitlab runner cycle
    job_result = monitor_gitlab_pipeline_job(tenant_name, gitlab_url, gitlab_token, site_id)
    #Job failed. Raises HTTP error
    if job_result['status'] == 'failed':
        raise LookupError('Data changed, but job execution failed!')

    #inserting back id so we have and id on response
    updated_data['id'] = updated_data['site_id']
    return updated_data
    






def validate_data_sent_by_user(current_data,new_data):
    """
    Get a specific wan site for a specific client/tenant.
    It uses the tenant_name and site_id provided as a part of the path/URL to query gitlab on a specific project (a specific wan_site/CPE).

    Parameters:
        current_data  (dict): JSON with current wan_site data
        new_data      (dict): JSON sent by the user with modified data for wan_site

    Returns:
        dict: WAN site with validated and updated data.

    Raises:
        ValueError: if any value is not validated
    """

    #Boolean to check if submitted data is different from existing data
    changed_data = False

    #Regex used for field validation
    string_regex        = '^[a-zA-Z0-9_\-\s]{1,20}$'
    interface_ip_regex  = "^(([1-9]?[0-9]|1[0-9]{2}|2[0-4][0-9]|25[0-5])\.){3}([1-9]?[0-9]|1[0-9]{2}|2[0-4][0-9]|25[0-5])\/([1-9]|[1-2][0-9]|3[0-1])$"
    helper_address_regex= "^(([1-9]?[0-9]|1[0-9]{2}|2[0-4][0-9]|25[0-5])\.){3}([1-9]?[0-9]|1[0-9]{2}|2[0-4][0-9]|25[0-5])$"

    #just to keep a record to easy read on the demo, will not be used here. On production code can be removed.
    #just to keep a record to easy read on the demo, will not be used here. On production code can be removed.
    acl_action_regex    = "^(permit|deny)$"
    acl_src_dst_regex   = "^(^(([1-9]?[0-9]|1[0-9]{2}|2[0-4][0-9]|25[0-5])\.){3}([1-9]?[0-9]|1[0-9]{2}|2[0-4][0-9]|25[0-5])\/([1-9]|[1-2][0-9]|3[0-2])$|any$)"
    acl_protocol_regex  = "^(tcp|udp|icmp|ip|gre)$"
    acl_port_regex      = "^[0-9]{1,5}-[0-9]{1,5}$|^(?![\s\S])$|^([0-9]{1,4}|[1-5][0-9]{4}|6[0-4][0-9]{3}|65[0-4][0-9]{2}|655[0-2][0-9]|6553[0-5])$"

    acl_max_rules       = 20
    #just to keep a record to easy read on the demo, will not be used here. On production code can be removed.
    #just to keep a record to easy read on the demo, will not be used here. On production code can be removed.


    #You MUST NOT trust the data sent. You MUST make strict validation from each field.
    #Also, for more security, we won't use the whole data sent by the user. We use our current data (current_data) as reference, and use new_data to update values in it. We will validate only fields that can be changed by users.
    #We will validate basically 3 things here:
    #1- If fields matches their regex.
    #2- If each ACL size is 20 (maximum number of ACL lines - a.k.a. ACEs)
    #3- If either source or destination IPs on ACEs belongs to interface LAN Address subnet (ex.: LAN=192.168.0.1/24. dst or src IP MUST be inside this range)
    #Also, if user sent a new lan_interface, or changed its "interface_name", error will be thrown.



    if 'custom_site_name' in new_data:
        if not re.match(string_regex, new_data['custom_site_name']):
            raise ValueError('Field "custom_site_name" with value "'+new_data['custom_site_name']+'" not valid. Valid regex:'+string_regex)
        #Validated. Update our current data
        if current_data['custom_site_name'] != new_data['custom_site_name']:
            changed_data = True
            current_data['custom_site_name'] = new_data['custom_site_name']
        
    if 'lan_interfaces' in new_data:
        if len(new_data['lan_interfaces']) > 48: #Just stupid DoS protection
            raise ValueError('submitted data has more "lan_interfaces" than 48... Aborting.')
        #Looping for each LAN interface of the device
        for interface in new_data['lan_interfaces']:
            if 'interface_name' not in interface:
                #Interface does not have a name! We don't know which one user is changing!
                raise ValueError('One of the interfaces does not have a "interface_name" to match.')
            
            #Checking if current edited interface exists on our data. If it doesn't, its an error.
            interface_index=0
            found_interface=False
            for value in current_data['lan_interfaces']:
                if interface['interface_name'] == value['interface_name']:
                    #Getting ID of interface that user is changing so we can update our data if validated
                    cur_interface=interface_index
                    found_interface=True
                    break
                interface_index=interface_index+1
            if not found_interface:
                raise ValueError('Interface '+interface['interface_name']+' not found on current wan site')

            if 'ip_address' in interface:
                if not re.match(interface_ip_regex, interface['ip_address']):
                    raise ValueError('Field "ip_address" with value "'+interface['ip_address']+'" not valid. Valid regex:'+interface_ip_regex)
                if current_data['lan_interfaces'][cur_interface]['ip_address'] != interface['ip_address']:
                    changed_data = True
                    current_data['lan_interfaces'][cur_interface]['ip_address'] = interface['ip_address']
                interface_ip_address = interface['ip_address'] #To use on ACL validation
            else:
                interface_ip_address = current_data['lan_interfaces'][cur_interface]['ip_address'] #To use on ACL validation

            if 'description' in interface:
                if not re.match(string_regex, interface['description']):
                    raise ValueError('Field "description" with value "'+interface['description']+'" not valid. Valid regex:'+string_regex)
                if current_data['lan_interfaces'][cur_interface]['description'] != interface['description']:
                    changed_data = True
                    current_data['lan_interfaces'][cur_interface]['description'] = interface['description']

            if 'helper_address' in interface:
                if not re.match(helper_address_regex, interface['helper_address']):
                    raise ValueError('Field "helper_address" with value "'+interface['helper_address']+'" not valid. Valid regex:'+helper_address_regex)
                if current_data['lan_interfaces'][cur_interface]['helper_address'] != interface['helper_address']:
                    changed_data = True
                    current_data['lan_interfaces'][cur_interface]['helper_address'] = interface['helper_address']

            #Starting to validate ACLs!
            if 'in_acl' in interface:                              
                #If we reached this line, ACL is ok and we can update our data
                if validate_acl(interface['in_acl'],interface_ip_address):
                    if json.dumps(current_data['lan_interfaces'][cur_interface]['in_acl']) != json.dumps(interface['in_acl']):
                        changed_data = True
                        current_data['lan_interfaces'][cur_interface]['in_acl'] = interface['in_acl']

            if 'out_acl' in interface:                              
                #If we reached this line, ACL is ok and we can update our data
                if validate_acl(interface['out_acl'],interface_ip_address):
                    if json.dumps(current_data['lan_interfaces'][cur_interface]['out_acl']) != json.dumps(interface['out_acl']):
                        changed_data = True
                        current_data['lan_interfaces'][cur_interface]['out_acl'] = interface['out_acl']

    if changed_data == False:
        #Should be HTTP 400...
        raise ValueError('No change submitted')


    return current_data








def validate_acl(acl,interface_ip_address):
    """
    Validate every aspect of ACLs

    Parameters:
        acl                      (dict): JSON with current in or out ACL
        interface_ip_address      (str): IP address and network on interface. E.g.: 192.168.0.1/24

    Returns:
        True: if validated

    Raises:
        ValueError: if any value is not validated
    """

    acl_action_regex    = "^(permit|deny)$"
    acl_src_dst_regex   = "^(^(([1-9]?[0-9]|1[0-9]{2}|2[0-4][0-9]|25[0-5])\.){3}([1-9]?[0-9]|1[0-9]{2}|2[0-4][0-9]|25[0-5])\/([1-9]|[1-2][0-9]|3[0-2])$|any$)"
    acl_protocol_regex  = "^(tcp|udp|icmp|ip|gre)$"
    acl_port_regex      = "^[0-9]{1,5}-[0-9]{1,5}$|^(?![\s\S])$|^([0-9]{1,4}|[1-5][0-9]{4}|6[0-4][0-9]{3}|65[0-4][0-9]{2}|655[0-2][0-9]|6553[0-5])$"

    acl_max_rules       = 20

    interface_subnet = IPNetwork(interface_ip_address)

    if len(acl) > acl_max_rules:
        raise ValueError('a "acl" has more than the maximum allowed rules ('+acl_max_rules+').')
    
    for acl_line in acl:
        #Validating required fields
        if 'action' not in acl_line or 'src' not in acl_line or 'dst' not in acl_line or 'protocol' not in acl_line or 'port' not in acl_line: #Could be an 'all()'
            raise ValueError('"acl" missing one needed field: action or src or dst or protocol or port.')
        
        #Validating if ACE has a field different from the permited ones
        if len(acl_line) > 5: #Just stupid DoS protection
            raise ValueError('"acl" has more than defined field numbers.')
        for key in acl_line:
            if key not in ['action','src','dst','protocol','port']:
                raise ValueError('"acl" has a not valid field "'+key+'".')

        #Validating each field
        if not re.match(acl_action_regex, acl_line['action']):
            raise ValueError('Field "action" in one ACL line with value "'+acl_line['action']+'" not valid. Valid regex:'+acl_action_regex)
        
        if not re.match(acl_src_dst_regex, acl_line['src']):
            raise ValueError('Field "src" in one ACL line with value "'+acl_line['src']+'" not valid. Valid regex:'+acl_src_dst_regex)

        if not re.match(acl_src_dst_regex, acl_line['dst']):
            raise ValueError('Field "dst" in one ACL line with value "'+acl_line['dst']+'" not valid. Valid regex:'+acl_src_dst_regex)
        
        if not re.match(acl_protocol_regex, acl_line['protocol']):
            raise ValueError('Field "protocol" in one ACL line with value "'+acl_line['protocol']+'" not valid. Valid regex:'+acl_protocol_regex)

        if not re.match(acl_port_regex, acl_line['port']):
            raise ValueError('Field "port" in one ACL line with value "'+acl_line['port']+'" not valid. Valid regex:'+acl_port_regex)

        #Validating if port is empty in case protocol is gre, ip or icmp
        if acl_line['protocol'] == "ip" or acl_line['protocol'] == "icmp" or acl_line['protocol'] == "gre":
            if acl_line['port'] != "":
                raise ValueError('For IP, GRE or ICMP protocols, "port" must be empty!')

        
        #Converting 'any' to '0.0.0.0/0' to correct check networks values            
        src_address = acl_line['src']
        if src_address == 'any':
            src_address = '0.0.0.0/0' #If its 'any' we must convert it to 0.0.0.0/0 so netaddr can correctly understand it
        dst_address = acl_line['dst']
        if dst_address == 'any':
            dst_address = '0.0.0.0/0' #If its 'any' we must convert it to 0.0.0.0/0 so netaddr can correctly understand it
        
        #Checking if ip/mask provided are correct! e.g.: 192.168.0.7/24 is wrong. 192.168.0.7/32 is correct
        if (str(IPNetwork(src_address).cidr) != src_address):
            raise ValueError('SRC '+src_address+' address/mask is not correct! eg.: 192.168.0.7/24 is not valid, should be 192.168.0.7/32 or 192.168.0.0/24')
        if (str(IPNetwork(dst_address).cidr) != dst_address):
            raise ValueError('DST '+dst_address+' address/mask is not correct! eg.: 192.168.0.7/24 is not valid, should be 192.168.0.7/32 or 192.168.0.0/24.')

        #Checking if either src or dst address are on subnet range from the interface LAN ip address
        if not IPNetwork(src_address) in IPNetwork(interface_subnet) and not IPNetwork(dst_address) in IPNetwork(interface_subnet):
            raise ValueError('Either "src" or "dst" ip address on a ACL line is not in interface LAN subnet! Interface IP: '+interface_ip_address+'."src":'+acl_line['src']+'. "dst":'+acl_line['dst']+'.')

    #Valid
    return True











def monitor_gitlab_pipeline_job(tenant_name,gitlab_url,gitlab_token,site_id):
    """
    Monitor CI/CD pipeline execution after a new data is sent to gitlab

    Parameters:
        tenant_name   (str): The name of a client/tenant.
        gitlab_url    (str): Gitlab URL.
        gitlab_token  (str): Gitlab Auth/Bearer Token.
        site_id       (str): Specific WAN site ID.

    Returns:
        dict: Job status information after execution (eg.: failed, sucessfull)

    Raises:
        LookupError: Error getting info from gitlab
    """


    last_job_id = get_gitlab_pipeline_lastjob(tenant_name,gitlab_url,gitlab_token,site_id)


    # Monitoring our job until it fail or finish
    job_status = "unknown"
    while job_status != 'failed' and job_status != 'success':
        # Requesting the last pipeline job from the host
        job=get_gitlab_pipeline_job_status(tenant_name,gitlab_url,gitlab_token,site_id,last_job_id)
        job_status=job['status']
        time.sleep(5)
    return job






def get_gitlab_pipeline_lastjob(tenant_name,gitlab_url,gitlab_token,site_id):
    """
    Monitor CI/CD pipeline execution after a new data is sent to gitlab

    Parameters:
        tenant_name   (str): The name of a client/tenant.
        gitlab_url    (str): Gitlab URL.
        gitlab_token  (str): Gitlab Auth/Bearer Token.
        site_id       (str): Specific WAN site ID.

    Returns:
        int: Last pipeline job Id for project

    Raises:
        LookupError: Error getting info from gitlab
    """


    # Requesting a list of pipeline jobs for current site
    request_url = gitlab_url + "/api/v4/projects/" + service_name + "%2F" + tenant_name + "%2F" + site_id + "/pipelines?per_page=1" 
    # Make HTTP request to gitlab
    response = requests.get(request_url, headers={'PRIVATE-TOKEN': gitlab_token})
    # Check for error on gitlab response
    if response.status_code != 200:
        raise LookupError('Received Code {response.status_code} from gitlab. Full Response: "{response.content}"')  
    response_json = response.json()
    return response_json[0]['id']
    




def get_gitlab_pipeline_job_status(tenant_name,gitlab_url,gitlab_token,site_id,job_id):
    """
    Monitor CI/CD pipeline execution after a new data is sent to gitlab

    Parameters:
        tenant_name   (str): The name of a client/tenant.
        gitlab_url    (str): Gitlab URL.
        gitlab_token  (str): Gitlab Auth/Bearer Token.
        site_id       (str): Specific WAN site ID.
        job_id        (int): Id of the job

    Returns:
        dict: Job Information
    Raises:
        LookupError: Error getting info from gitlab
    """

    request_url = gitlab_url + "/api/v4/projects/" + service_name + "%2F" + tenant_name + "%2F" + site_id + "/pipelines/" + str(job_id)
    # Make HTTP request to gitlab
    response = requests.get(request_url, headers={'PRIVATE-TOKEN': gitlab_token})
    # Check for error on gitlab response
    if response.status_code != 200:
        raise LookupError('Received Code {response.status_code} from gitlab. Full Response: "{response.content}"')
    response_json = response.json()
    return response_json







def get_gitlab_pipeline_last_jobs(tenant_name,gitlab_url,gitlab_token,site_id,number_of_jobs):
    """
    Monitor CI/CD pipeline execution after a new data is sent to gitlab

    Parameters:
        tenant_name   (str): The name of a client/tenant.
        gitlab_url    (str): Gitlab URL.
        gitlab_token  (str): Gitlab Auth/Bearer Token.
        site_id       (str): Specific WAN site ID.
        number_of_jobs(int): Number of last jobs to get.

    Returns:
        int: Last pipeline job Id for project

    Raises:
        LookupError: Error getting info from gitlab
    """

    list_of_jobs = [] #our list of jobs

    # Getting last 5 jobs
    # Requesting a list of pipeline jobs for current site
    request_url = gitlab_url + "/api/v4/projects/" + service_name + "%2F" + tenant_name + "%2F" + site_id + "/pipelines?per_page=" + str(number_of_jobs)
    # Make HTTP request to gitlab
    response = requests.get(request_url, headers={'PRIVATE-TOKEN': gitlab_token})
    # Check for error on gitlab response
    if response.status_code != 200:
        raise LookupError('Received Code {response.status_code} from gitlab. Full Response: "{response.content}"')  
    response_json = response.json()


    # For each submitted job, get the commit. 
    for job in response_json:
        job_to_send = {}
        job_to_send['status'] = job['status']
        job_to_send['id'] = job['created_at'] #adding ID
        job_to_send['created_at'] = job['created_at']
        job_to_send['updated_at'] = job['updated_at']
        request_url = gitlab_url + "/api/v4/projects/" + service_name + "%2F" + tenant_name + "%2F" + site_id + "/repository/tree?ref="+job['sha']
        # Make HTTP request to gitlab
        response = requests.get(request_url, headers={'PRIVATE-TOKEN': gitlab_token})
        # Check for error on gitlab response
        if response.status_code != 200:
            raise LookupError('Received Code {response.status_code} from gitlab. Full Response: "{response.content}"')  
        commit_response_json = response.json()

        #get wan_site_data.json id from commit and request bloc content
        for commit_file in commit_response_json:
            if commit_file['name'] == "wan_site_data.json":
                #found file
                #get blob content from file id in base64
                request_url = gitlab_url + "/api/v4/projects/" + service_name + "%2F" + tenant_name + "%2F" + site_id + "/repository/blobs/"+commit_file["id"]
                # Make HTTP request to gitlab
                response = requests.get(request_url, headers={'PRIVATE-TOKEN': gitlab_token})
                # Check for error on gitlab response
                job_to_send['content'] = ''
                if response.status_code == 200:
                    #Sometimes response can be 404 if no change is submited on file (bug?). So, we only append a result to content if its HTTP 200 answer
                    blob_response_json = response.json()
                    job_to_send['content'] = base64.b64decode(blob_response_json['content'].encode('ascii')).decode()
                
        list_of_jobs.append(job_to_send)

        

    # Getting commit content
    return list_of_jobs