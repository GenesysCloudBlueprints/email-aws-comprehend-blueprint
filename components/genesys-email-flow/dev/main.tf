terraform {
  backend "local" {
    path = "/Users/johncarnell/genesys_terraform/carnell1_dev/tfstate"
  }

  required_providers {
    genesyscloud = {
      source = "mypurecloud/genesyscloud"
    }
  }
}

provider "genesyscloud" {
  sdk_debug = true
}

module "classifier_users" {
  source = "../modules/users"
}

module "classifier_queues" {
  source                   = "../modules/queues"
  classifier_queue_names   = ["401K", "IRA", "529", "GeneralSupport"]
  classifier_queue_members = module.classifier_users.user_ids
}

module "classifier_email_routes" {
  source               = "../modules/email_routes"
  genesys_email_domain = var.genesys_email_domain
}

module "classifier_data_actions" {
  source             = "../modules/data_actions"
  classifier_url     = var.classifier_url
  classifier_api_key = var.classifier_api_key
}

module "classifier_email_flow" {
  source                      = "../modules/email_flow"
  genesys_email_domain        = var.genesys_email_domain
  genesys_email_domain_region = var.genesys_email_domain_region

  depends_on = [module.classifier_data_actions, module.classifier_queues]
}
