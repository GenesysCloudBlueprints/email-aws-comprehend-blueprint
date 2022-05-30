
terraform {
  required_providers {
    genesyscloud = {
      source = "mypurecloud/genesyscloud"

    }
  }
}

#
# Description:  
#
# Uploads the yaml file as an Inbound Email Flow in Genesys Cloud.
# The flow includes data actions and a queue, so this module depends on the creation of both.
# 

resource "genesyscloud_flow" "test-flow" {
  filepath = "./EmailComprehendFlow.yaml"
}
