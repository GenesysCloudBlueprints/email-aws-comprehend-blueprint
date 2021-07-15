We are now in the last stage of setting up this blueprint. In this last step, we are going to use Genesys Cloud `CX as Code`, the Genesys Cloud Python SDK and Genesys Cloud's Archy tools to deploy all of the Genesys Cloud objects used to handle the email flow in this blueprint. 

# Pre-Requisites

1. **Install Terraform**. Install the latest Terraform binary. Instructions for installing Terraform can be found [here](https://www.terraform.io/downloads.html). 
2. **Install Archy**. Install the latest Genesys Cloud Archy import/export tool. Instructions for installing Archy can be found [here](https://developer.genesys.cloud/devapps/archy/).
3. **Install Python 3.7**. This Terraform flow wrappers an Archy call using Python 3.7+. Please make sure you have Python installed.
4. **Install the Genesys Cloud python SDK**. The python script that calls Archy also uses our Genesys Cloud python SDK. Instructions for installing the Genesys Cloud python SDK can be found [here](https://developer.genesys.cloud/api/rest/client-libraries/python/).

# Deployment Steps
Once the pre-requisite tools are installed you need to take the following actions to deploy your flow.

1. **Set your credentials and AWS region**. 
2. **Setup your `CX as Code` flow.auto.tfvars file**.
3. **Configure your Terraform backend**.
4. **Initialize Terraform**.
5. **Apply your Terraform changes**.

## Setup your credentials and AWS Regions. 
All Genesys Cloud OAuth2 credentials and AWS region configuration used by `CX as Code`is handled through environment variables. 
The following environment variables need to be set before you run your Terraform configuration

1. `GENESYSCLOUD_OAUTHCLIENT_ID`. The OAuth2 Client id of the Genesys Cloud OAuth2 client credential grant the Genesys Cloud `Cx as Code` provider will run under. Information on how to setup a Genesys Cloud OAuth2 client credential grant can be found [here](https://help.mypurecloud.com/articles/create-an-oauth-client/).

2. `GENESYSCLOUD_OAUTHCLIENT_SECRET`. The OAuth2 secret of the Genesys Cloud OAuth2 client credential grant the Genesys Cloud `Cx s Code` provider will run under.

3. `GENESYSCLOUD_REGION`. The region used by the Genesys Cloud OAuth2 client. Valid values can be found in the `AWS region` field listed [here](https://developer.genesys.cloud/api/rest/).

4. `GENESYSCLOUD_API_REGION`. The Genesys Cloud API endpoint the Genesys Cloud SDK will connect with. Valid values can be found in the `API SERVER` field listed [here](https://developer.genesys.cloud/api/rest/).

5. `GENESYSCLOUD_ARCHY_REGION`. The Genesys Cloud domain name that Archy uses to resolve the Genesys Cloud AWS region to connect to. Valid locations include: 
```
    apne2.pure.cloud
    aps1.pure.cloud
    cac1.pure.cloud
    euw2.pure.cloud
    mypurecloud.com
    mypurecloud.com.au
    mypurecloud.de
    mypurecloud.ie
    mypurecloud.jp
    usw2.pure.cloud
  ```                             

## Setup your `CX as Code` flow.auto.tfvars file
All application configuration for this flow is kept in the `components/genesys-email-flow/dev/flow.auto.tfvars`file. Please configure the parameters contained in the file to values specific to your organization. The values configured this file include:

1. `genesys_email_domain`. A globally unique name for your Genesys Cloud email domain name. If you choose a name that already exists, the execution of the `CX as Code` script(s) will fail.

2. `genesys_email_domain_region`. The suffix for the email domain. Valid values are based on the AWS region. Valid values include:
  ```
      US East -------> mypurecloud.com
      US West --------> pure.cloud
      Canada  --------> pure.cloud
      Europe(Ireland)   --------> mypurecloud.ie
      Europe(London)    --------> pure.cloud
      Europe(Frankfurt) --------> mypurecloud.de
      Asia(Mumba)       --------> pure.cloud
      Asia(Tokyo)       --------> mypurecloud.jp
      Asia(Seoul)       --------> pure.cloud
      Asia(Sydney)      --------> mypurecloud.au
   ```
   **Note**: Your `genesys_email_domain_region` must be in the same region as your Genesys Cloud organization.

   This script will create an email route called `support` that users can send emails to.  So for example, if you set your `genesys_email_domain` to be `devengagedev`and your `genesys_email_domain_region` to be `pure.cloud`, when this `Cx as Code` script is run any emails set to `support@devengagedev.pure.cloud` will be processed by the email architect flow created by this script.

3. `classifier_url`. The endpoint used to invoke the classifier. The endpoint you set here should be the endpoint created when setting up the `components/aws-comprehend` part of this blueprint.

4. `classifier_api_key`. The API key you needed to invoke the endpoint defined in step #3 above. The api key you set here should be the API key created when setting up the `components/aws-comprehend` part of this blueprint.

## Configure your Terraform environment

Terraform requires a backend for storing state. For purposes of this blueprint, the backend was configured to be in a file separate from the project files. Modify the `components/genesys-email-flow/dev/main.tf` file to point where you want your backend file to be created. Specifically modify, this section of the code:

```
terraform {
  backend "local"  {
      path ="/Users/johncarnell/genesys_terraform/carnell1_dev/tfstate"   #Point to your own directory and make sure the directory exists. The file
                                                                          #created will be called tfstate. 
  }
.....  # Code not displayed for conciseness
}
```

## Initialize Terraform
Before you run `Cx as Code` for the first time you need to change to the `components/genesys-email-flow/dev` directory and initialize Terraform by running `terraform init`.

## Apply your Terraform changes
Once `terraform init` has been run, you can create all of the Genesys Cloud objects by running:

`terraform apply --auto-approve`

To teardown all of the objects created by these flows run:

`terraform destroy --auto-approve`

At this point, if you have followed all of the steps properly you should now be able to login into your Genesys org and see all of your queues, integration, data action, email architect flow, email domains and routes created.

**NOTE:  The Terraform scripts attempts to create an email domain route. Normally,Genesys Cloud, by default, only allows one domain router per organization. If you already have a domain route please use the id of that existing route in this script.  (We are working on data source for email domain routes so we expect this be a temporary issue)  Alternatively, you can contact the Genesys Cloud [CARE](https://help.mypurecloud.com/articles/contact-genesys-cloud-care/) team to request an increase the rate limit be increased for this organization.**

# Post-Deployment
This is the end of the setup for this blueprint. If you followed all three components steps of this blueprint (train the classifier in `components/aws-comprehend`, create the classifier lambda in `aws-classifier-lambda`, and create the Genesys objects in `components/genesys-email-flow`) you should now be able to send email to your classifier and route the email to the appropriate queue. The email that I have been testing will send the user's email to the `IRA` queue:

```
1. Can I rollover my existing 401K to my IRA. 
2. Is an IRA tax-deferred? 
3. Can I make contributions from my IRA to a charitable organization?
4. Am I able to borrow money from my IRA?
5. What is the minimum age I have to be to start taking money out of my IRA?
 
Thanks,
  John
```