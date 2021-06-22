
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
# There is some hackery a foot here. Archy is a standalone command line tool so it can not participate in all of the terraform goodness natively.
# Using a local-exec to handle the creation and deletion of an archy flow.  Note:  I can not seem to delete a flow with the archy tool so I use
# a shell script to call the Genesys Cloud CLI to lookup the flow and then delete it via the CLI
# 

resource "null_resource" "deploy_files" {


  provisioner "local-exec" {
    command = "${path.module}/scripts/manage_flow.py CREATE ${var.genesys_email_domain} ${var.genesys_email_domain_region}"
  }

  provisioner "local-exec" {
    when    = destroy
    command = "${path.module}/scripts/manage_flow.py DELETE NA NA"   
    on_failure = continue
  }

}
