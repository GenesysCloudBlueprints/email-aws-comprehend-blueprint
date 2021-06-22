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


resource "genesyscloud_routing_email_domain" "devengage_email_domain" {
  domain_id = var.genesys_email_domain
  subdomain = true
}

# # In order to map the route to the flow we need the flow.  Since Archy is not a first class CX as Code entity, we drop down to the
# # cli to run a shell script.  This shell script looks up the flow by name and type and then maps the data to a data source.
# # Functional is sometimes ugly and ugly sometimes get the job done
# data "external" "lookup_comprehend_flow_id" {
#   program = ["sh", "scripts/lookup_comprehend_flow_id.sh"]

#   depends_on = [null_resource.deploy_files]
# }

# # Create the route.  Notice how the flow id references a "data" source.  This data source is mapped from the data command above.
# resource "genesyscloud_routing_email_route" "devengage_support_route" {
#   domain_id  = "devengage.mypurecloud.com"
#   pattern    = "support"
#   from_email = "support@devengage.mypurecloud.com"
#   from_name  = "Financial Services Support"
#   flow_id    = data.external.lookup_comprehend_flow_id.result.flow_id

#   depends_on = [null_resource.deploy_files]
# }
