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
# Last step in the process.  We are going to create the email domain and route.  Since this has to happen after the archy flow,
# we explicitly create a dependency on the archy flow.
#
# Note:  Currently we only allow a two email domain routes per Genesys Cloud organization.  You can contact CARE for an additional email route.  This
# command will fail if there is already have two email routes present.



resource "genesyscloud_routing_email_domain" "devengage_email_domain" {
  domain_id = var.genesys_email_domain
  subdomain = true
}

data "genesyscloud_flow" "email-flow" {
  name = var.genesys_email_flow
}

resource "genesyscloud_routing_email_route" "support-route" {
  domain_id    = "${var.genesys_email_domain}.${var.genesys_email_domain_region}"
  pattern      = "support"
  from_name    = "Financial Services Support"
  from_email   = "support@${var.genesys_email_domain}.${var.genesys_email_domain_region}"
  flow_id      = data.genesyscloud_flow.email-flow.id
  depends_on   = [genesyscloud_routing_email_domain.devengage_email_domain]
}
