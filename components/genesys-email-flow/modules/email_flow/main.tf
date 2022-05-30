
terraform {
  required_providers {
    genesyscloud = {
      source = "mypurecloud/genesyscloud"

    }
  }
}

resource "genesyscloud_flow" "test-flow" {
  filepath = "./EmailComprehendFlow.yaml"
}
