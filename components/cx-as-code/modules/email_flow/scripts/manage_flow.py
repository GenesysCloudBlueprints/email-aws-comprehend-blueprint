#!/usr/bin/python

import subprocess
import sys
import json
import uuid
import os


SCRIPT_PATH = sys.path[0]
CLIENT_ID = os.environ["GENESYSCLOUD_OAUTHCLIENT_ID"]
CLIENT_SECRET = os.environ["GENESYSCLOUD_OAUTHCLIENT_SECRET"]
CLIENT_REGION = os.environ["GENESYSCLOUD_ARCHY_REGION"]
CLI_PROFILE = os.environ["GENESYSCLOUD_CLI_PROFILE"]

ACTION = sys.argv[1]
TARGET_DOMAIN = sys.argv[2]
TARGET_DOMAIN_NAME = sys.argv[3]


def deleteEmailRoute():
    print("\nDeleting email route for target domain: \n")
    cmd = "gc -p {} routing email domains routes list '{}'".format(CLI_PROFILE, TARGET_DOMAIN)

    output, error = subprocess.Popen(["/bin/bash", "-c", cmd], stdout=subprocess.PIPE, stderr=subprocess.PIPE).communicate()
    results = json.loads(output)

    if len(results["entities"]) > 0:
        routeId = results["entities"][0]["id"]
        cmd = "gc -p {} routing email domains routes delete {} {} && sleep 10".format(
            CLI_PROFILE, TARGET_DOMAIN, routeId
        )
        subprocess.Popen(["/bin/bash", "-c", cmd], stdout=subprocess.PIPE, stderr=subprocess.PIPE).communicate()

        print("Successfully deleted email route for target domain: {}").format(TARGET_DOMAIN)


def findFlowId():
    print("Finding flow id for EmailAWSComprehend flow\n")
    cmd = "gc -p {} flows list --nameOrDescription=EmailAWSComprehendFlow".format(CLI_PROFILE)

    output, error = subprocess.Popen(["/bin/bash", "-c", cmd], stdout=subprocess.PIPE, stderr=subprocess.PIPE).communicate()

    results = json.loads(output)
    flowId = results["entities"][0]["id"]
    print("Flow id found for EmailAWSComprehend flow: {}\n").format(flowId)
    return flowId


def createEmailRoute():
    flowId = findFlowId()
    print("Creating email route 'support' for flow id: {}\n").format(flowId)

    body = {
        "pattern": "support",
        "fromName": "Financial Services Support",
        "fromEmail": "support@" + TARGET_DOMAIN + "." + TARGET_DOMAIN_NAME,
        "flow": {"id": flowId},
    }
    fileName = "{}/output/{}.json".format(SCRIPT_PATH, str(uuid.uuid4()))
    file = open(fileName, "w")
    bodyString = json.dumps(body)
    file.write(bodyString)
    file.close()

    cmd = "gc -p {} routing email domains routes create {} -f {}".format(CLI_PROFILE, TARGET_DOMAIN + "." + TARGET_DOMAIN_NAME, fileName)

    results, error = subprocess.Popen(["/bin/bash", "-c", cmd], stdout=subprocess.PIPE, stderr=subprocess.PIPE).communicate()
    print("Email route 'support' created for flow id: {}\n").format(flowId)


def createArchyFlow():
    print("Creating Archy flow \n")
    cmd = "sleep 10 && archy publish --forceUnlock --file={}/EmailComprehendFlow.yaml --clientId {} --clientSecret {} --location {}  --overwriteResultsFile --resultsFile {}/output/results.json && sleep 10".format(
        SCRIPT_PATH, CLIENT_ID, CLIENT_SECRET, CLIENT_REGION, SCRIPT_PATH
    )

    results, error = subprocess.Popen(["/bin/bash", "-c", cmd], stdout=subprocess.PIPE, stderr=subprocess.PIPE).communicate()
    flowId = findFlowId()
    print("Archy flow created with flow id: {}\n").format(flowId)


def deleteArchyFlow():
    flowId = findFlowId()
    print("Deleting archy flow: {}\n").format(flowId)
    cmd = "gc -p {} flows delete {}".format(CLI_PROFILE, flowId)
    results, error = subprocess.Popen(["/bin/bash", "-c", cmd], stdout=subprocess.PIPE, stderr=subprocess.PIPE).communicate()

    print("Archy flow {} deleted\n").format(flowId)

if ACTION == "CREATE":
    deleteEmailRoute()
    createArchyFlow()
    createEmailRoute()

if ACTION == "DELETE":
    deleteArchyFlow()
