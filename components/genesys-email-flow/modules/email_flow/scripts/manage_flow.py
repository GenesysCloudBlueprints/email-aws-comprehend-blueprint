import subprocess
import sys
import os
import time
import PureCloudPlatformClientV2

SCRIPT_PATH = sys.path[0]
CLIENT_ID = os.environ["GENESYSCLOUD_OAUTHCLIENT_ID"]
CLIENT_SECRET = os.environ["GENESYSCLOUD_OAUTHCLIENT_SECRET"]
CLIENT_REGION = os.environ["GENESYSCLOUD_REGION"]
CLIENT_REGION = os.environ["GENESYSCLOUD_ARCHY_REGION"]
CLIENT_API_REGION = os.environ["GENESYSCLOUD_API_REGION"]

PureCloudPlatformClientV2.configuration.host = 	CLIENT_API_REGION
apiClient = PureCloudPlatformClientV2.api_client.ApiClient().get_client_credentials_token(CLIENT_ID, CLIENT_SECRET)
architectApi = PureCloudPlatformClientV2.ArchitectApi(apiClient)

ACTION = sys.argv[1]

def findFlowId():
    print("Finding flow id for EmailAWSComprehend flow\n")
    results = architectApi.get_flows(name_or_description="EmailAWSComprehendFlow")
    flowId = results.entities[0].id

    print("Flow id found for EmailAWSComprehend flow: {}\n".format(flowId))
    return flowId

def createArchyFlow():
    print("Creating Archy flow \n")
   
    cmd = "archy publish --forceUnlock --file={}/EmailComprehendFlow.yaml --clientId {} --clientSecret {} --location {}  --overwriteResultsFile --resultsFile {}/output/results.json".format(
        SCRIPT_PATH, CLIENT_ID, CLIENT_SECRET, CLIENT_REGION, SCRIPT_PATH
    )
    
    time.sleep(10)
    subprocess.run(cmd, shell=True,stdout=subprocess.PIPE, stderr=subprocess.PIPE, check=True)
    time.sleep(10)
  
    flowId = findFlowId()
    print("Archy flow created with flow id: {}\n".format(flowId))

def deleteArchyFlow():
    flowId = findFlowId()
    time.sleep(20.0)
    architectApi.delete_flow(flowId)
    print("Archy flow {} deleted\n".format(flowId))

if ACTION == "CREATE":
    createArchyFlow()

if ACTION == "DELETE":
    deleteArchyFlow()
