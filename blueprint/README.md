---
title: Set up intelligent routing of emails using Genesys Cloud and AWS Comprehend
author: john.carnell
indextype: blueprint
icon: blueprint
image: images/EmailClassiiferNoNumber.png
category: 5
summary: |
  This Genesys Cloud Developer Blueprint explains how to build an inbound email flow in Genesys Cloud that leverages AWS Comprehend's machine learning classifier to classify an email and route the email to a specific queue.
---

This Genesys Cloud Developer Blueprint explains how to build an inbound email flow in Genesys Cloud that leverages AWS Comprehend's machine learning classifier to classify an email and route the email to a specific queue. The blueprint also demonstrates how to train an AWS machine learning classifier, leverage the AWS API Gateway endpoint, use AWS Lambda to build a microservice which invokes the classifier, and leverage **CX as Code** configuration tool to deploy all of the required Genesys Cloud objects. 

In this blueprint, the following scenario is taken under consideration and the procedures capture the scenario. We recommend you to make necessary adjustments for your enviroment. The solution is for:
-  A financial services business that has product offerings for 401Ks, IRAs and 529 college savings account.
-  The financial services group has 3 distinct call center groups with agents who specialize in each of these financial service products. 

When an email is sent to an email account owned by the organization, the company wants to have a Genesys Cloud architect email flow process the email and then use a machine learning model to classify the email. Based on the email contents, the email should be routed to a queue specific to the particular topic area. If the machine learning classifier is unable classify the incoming email, the financial services company wants to send the email to a general support queue.

For this blueprint we are going to use AWS Comprehend to perform the machine learning classification. The diagram below shows all of the components involved along with the general flow of activity involved in the solution.

![Email Routing and Classification using AWS Comprehend](images/EmailClassifier.png "Routing and Classification using AWS Comprehend")

The following actions take place in the diagram above:

1. A customer sends an email to an email address backed by a Genesys Cloud [architect email flow](https://help.mypurecloud.com/articles/inbound-email-flows/).

2. When an email is received the email architect flow will use a Genesys Cloud [data action](https://help.mypurecloud.com/articles/about-the-data-actions-integrations/) to invoke a REST-based service and send the email body and subject to the REST service for classification.

3. A REST service will be exposed by [AWS API gateway](https://aws.amazon.com/api-gateway/). The API gateway will forward the request onto an [AWS Lambda](https://aws.amazon.com/lambda/) to process the classification request. This lambda will invoke an [AWS Comprehend](https://aws.amazon.com/comprehend/) classifier endpoint to classify the contents of the email body in real-time. If the lambda is able to classify the email at a 75% confidence or higher level, it will return one of three categories back to the email flow: `401K`, `IRA`, or `529`. The email flow will then lookup the queue id and route the email to the queue. If the REST classifier can not reach this level of confidence, the REST service will return an empty string. In this case, the call flow will fallback to a general support queue.

4. The flow takes the returned classification, looks up the queue with the same name and then routes the email to the targeted queue.

5. When an agent receives the email, they will respond to the customer directly from within the Genesys Cloud application.

* [Solution components](#solution-components "Goes to the Solution components section")
* [Requirements](#requirements "Goes to the Requirements section")
* [Implementation steps](#implementation-steps "Goes to the Implementation steps section")
* [Additional resources](#additional-resources "Goes to the Additional resources section")

## Solution components

This solution requires the following components:

* **Genesys Cloud**. A suite of Genesys cloud services for enterprise-grade communications, collaboration, and contact center management. You deploy the architect email flow, integration, data actions, queues and email configuration in Genesys Cloud. 

* **AWS Comprehend**. AWS Comprehend is an an AWS service that lets your train a machine learning model to classify a body of text. Using AWS Comprehend requires you to first train a classification model and then expose AWS endpoint to allow the service to be invoke for real-time analysis

* **AWS API Gateway and AWS Lambda**. The AWS API gateway is used to exposed a REST endpoint that is protected by an API key. Requests coming into the API gateway are forwarded to an AWS Lambda (written in Typescript) that will process the request and call the AWS Comprehend endpoint classified defined in the previous bullet.

## Prerequisites

### Specialized knowledge

* Administrator-level knowledge of Genesys Cloud
* AWS Cloud Practitioner-level knowledge of AWS IAM, AWS Comprehend, and AWS API Gateway, AWS Lambda, and the AWS JavaScript SDK
* Experience using the Genesys Cloud Platform API and Genesys Cloud Python SDK

### Genesys Cloud account

* A Genesys Cloud license. For more information, see [Genesys Cloud Pricing](https://www.genesys.com/pricing "Opens the Genesys Cloud pricing page") in the Genesys website.
* The Master Admin role. For more information, see [Roles and permissions overview](https://help.mypurecloud.com/?p=24360 "Opens the Roles and permissions overview article") in the Genesys Cloud Resource Center.
* **Install Terraform**. Install the latest Terraform binary. Instructions for installing Terraform can be found [here](https://www.terraform.io/downloads.html). 
* **Install Archy**. Install the latest Genesys Cloud Archy import/export tool. Instructions for installing Archy can be found [here](https://developer.genesys.cloud/devapps/archy/).
* **Install Python 3.7**. This Terraform flow wrappers an Archy call using Python 3.7+. Please make sure you have Python installed.
* **Install the Genesys Cloud python SDK**. The python script that calls Archy also uses our Genesys Cloud python SDK. Instructions for installing the Genesys Cloud python SDK can be found [here](https://developer.genesys.cloud/api/rest/client-libraries/python/).
### AWS account

* A user account with Administrator Access permission and full access to the following services:
  * IAM service
  * AWS Comprehend service
  * AWS API gateway service
  * AWS Lambda service
* AWS credentials. For more information on setting up your AWS credentials on your local machine see [here](https://docs.aws.amazon.com/sdkref/latest/guide/creds-config-files.html).
* Download and install the AWS CLI. For more information on installing the AWS CLI on your local machine see [here](https://aws.amazon.com/cli/).
* Install the Serverless framework on the machine you are going to run this deploy from. The documentation for downloading and installing the Serverless framework can be found here.
* Install NodeJS on your machine if you do not already have it. For this blueprint, I used version 14.15.0. If you do not have NodeJS on your machine, I recommend using [nvm](https://github.com/nvm-sh/nvm) (Node Version Manager) to install Node.

## Implementation steps

1. **Clone the [email-aws-comprehend-blueprint](https://github.com/GenesysCloudBlueprints/email-aws-comprehend-blueprint "Opens the email-aws-comprehend-blueprint repository in GitHub")**.

2. **Train the AWS Comprehend machine learning model**. To train and deploy the AWS Comprehend model, you need leverage the AWS command-line tool. Detailed instructions can for performing this step can be found [here](/components/aws-comprehend). 

3. **Deploy API Gateway and the AWS Lambda**. The API Gateway and the AWS Lambda are built using the [Serverless](https://www.serverless.com/) framework. Detailed instructions for performing this step can be found [here](/components/aws-classifier-lambda).

4. **Deploy the Genesys Cloud objects**. The Genesys Cloud objects are deployed using [CX as Code](https://developer.genesys.cloud/api/rest/CX-as-Code/). Detailed 
instructions for perform this step can be found [here](/components/genesys-email-flow).

### Train and deploy the classifier
Train an AWS Comprehend machine learning classifier to classify email messages sent from this blueprint's Genesys Cloud email flow. AWS Cloudformation does not have support for the AWS Comprehend API at this point. For the training and deploying the classifier, you will need to use either the AWS management console or the AWS CLI (Command Line Interface) to train the classifier. For this blueprint, we will use the AWS CLI.
In order to train and deploy the classifier you need to take the following steps.

**Note**: All AWS CLI commands are assumed to be run from the `components/aws-comprehend` directory.

1. Setup the S3 Bucket and copy the training corpus (`components/aws-comprehend/comprehendterm.csv`) to the created S3 bucket 
   `aws s3api create-bucket --acl private --bucket <<your-bucket-name-here>> --region <<Your region>>` 
   
   `aws s3 cp comprehendterms.csv s3://<<your-bucket-name-here>>`


2. Modify the `EmailClassifierBucketBucketAccessRole-Permission.json` to point to the S3 bucket just created. Lines 10 and 19 in the file need to be modified.

3. Create the role, create the policy and attach the role to the policy the AWS Comprehend Classifier will use.

   `aws iam create-role --role-name EmailClassifierBucketAccessRole --assume-role-policy-document file://EmailClassifierBucketAccessRole-TrustPolicy.json`

   `aws iam create-policy --policy-name BucketAccessPolicy --policy-document file://EmailClassifierBucketAccessRole-Permissions.json`

   `aws iam attach-role-policy --policy-arn <<POLICY ARN return from the aws iam create-policy command above>> --role-name EmailClassifierBucketAccessRole`
        
    **NOTE**: Document the `Arn` returned on the `aws iam create-role` call. You are going to need it for the `aws create-document-classifier` in the next step.

4. Train the AWS Comprehend document classifier.
    `aws comprehend create-document-classifier --document-classifier-name FinancialServices --data-access-role-arn <<ARN FROM STEP 2 HERE>> --input-data-config S3Uri=s3://<<YOUR BUCKET NAME HERE>> --language-code en` 

     **NOTE**: It can take several minutes before AWS completes the training of the classifier. You need to monitor the progress and only run step 4 after the classifier training is completed. The AWS CLI command to see your classifier status: 
     
     `aws comprehend list-document-classifiers` 
     
    Your classifier is trained once the `Status` attribute on the JSON returned from the command above has a value of `TRAINED`. Once your classifier is trained take note of the `DocumentClassifierArn` value. This value will be used in step below.

5. Create the real-time document classifier endpoint.
    
    `aws comprehend create-endpoint --endpoint-name emailclassifier --model-arn <<YOUR DocumentClassifierArn here>> --desired-inference-units 1`

    **NOTE**: It can take several minutes for the real-time classifier endpoint to become active. You can monitor the status of the endpoint by calling:
    
    `aws comprehend list-endpoints` 
    
    Look for the your endpoint name (e.g. emailclassifier). When the `Status` is set to `IN_SERVICE` the classifier is ready to be used.  Take note of the `EndpointArn` for the `emailclassifier` endpoint you created. This value will need to be set when you are deploying the classifier lambda later on
    in the blueprint.

6. Test the classifier. Once the classifier has become `IN_SERVICE` you can test it by issuing the following command. 

    `aws comprehend classify-document --text "Hey I had some questions about what I can use my 529 for in regards to my childrens college tuition. Can I spend the money on things other then tuition" --endpoint-arn <<YOUR EndpointArn>>`

  If everything is setup correctly, you should see JSON from the command above that looks similar to this:

  `
  {
    "Classes": [
        {
            "Name": "529",
            "Score": 0.7981914281845093
        },
        {
            "Name": "401K",
            "Score": 0.14315158128738403
        },
        {
            "Name": "IRA",
            "Score": 0.0586569607257843
        }
    ]
}
`

### Post-Deployment

At this point the setup of the AWS Comprehend classifier is complete. Take note of the `EndpointArn` as the value will be used in the next part of the blueprint setup, the deployment of the API Gateway and AWS Lambda that will be used to call the classifier is located [here](../aws-classifier-lambda).

### Deploy API Gateway and the AWS Lambda
After the AWS classifier has been setup, we need to deploy the microservice that will be used to pass the email body from the Genesys Cloud architect email flow to the AWS classifier. To implement this microservice, we are going to deploy an AWS lambda fronted by an AWS API gateway endpoint.
The lambda in question was built using Typescript and is built and deployed using the [Serverless](https://www.serverless.com/) framework.

1. Create a `.env.dev` file in the `components/aws-classifier-lambda` directory.  This file should contain 2 values: `CLASSIFIER_ARN` and `CLASSIFIER_CONFIDENCE_THRESHOLD`.  The `CLASSIFIER_ARN` should be set to `EndpointArn` created when you trained the classifier (reference the `components/aws-comprehend` on how to train the classifier). The `CLASSIFIER_CONFIDENCE_THRESHOLD` is a value between 0 and 1 that signifies the level of confidence you want the lambda to have before returning a classification. For example, if `CLASSIFIER_CONFIDENCE_THRESHOLD` equals .75, that means the classification returned by the AWS Comprehend classifier must be at or above 75% to return the classification. If the classification falls below this value, the lambda will return an empty string for the classification.  Shown below is an example `.env.dev` file.

```
CLASSIFIER_ARN=arn:aws:comprehend:us-east-1:000000000000:document-classifier-endpoint/emailclassifier-example-only
CLASSIFIER_CONFIDENCE_THRESHOLD=.75
```

If you did not write down the `EndpointArn` you can use the AWS cli command: `aws comprehend list-endpoints` command to retrieve the endpoint. The `EndpointArn` will be in the returned data.

2. Open a command-line window and in the `email-aws-comprehend-blueprint/components/aws-classifier-lambda` directory run the `npm i` command to download and install all of the third-party packages and dependences.  

3. Deploy the lambda using `serverless deploy` command. This will take about a minute to deploy and when the lambda is deploy there are two important pieces of information that need to be captured for using when deploying the Genesys Cloud flow:  `api key` and `endpoints`.

4. Test the lambda.  Once the lambda is complete you can test it from the command line by issuing the following command:

```shell
curl --location --request POST '<<YOUR API GATEWAY HERE>>' \
--header 'Accept: application/json' \
--header 'Content-Type: application/json' \
--header 'x-amazon-apigateway-api-key-source: HEADER' \
--header 'X-API-Key: <<YOUR API KEY HERE>>' \
--data-raw '{
    "EmailSubject": "Question about IRA",
    "EmailBody": "Hi guys,\r\n\r\nI have some questions about my IRA?  \r\n\r\n1.  Can I rollover my existing 401K to my IRA.  \r\n2.  Is an IRA tax-deferred? \r\n3.  Can I make contributions from my IRA to a charitable organization?\r\n4.  Am I able to borrow money from my IRA?\r\n5.  What is the minimum age I have to be to start taking money out of my IRA?\r\n\r\nThanks,\r\n   John"
}'
```

If everything has deployed correctly you should see a JSON payload with the classification of the document along with the confidence level. For example, when I run the code against my own lambda, I see the following results:

```json
{"QueueName":"IRA","Confidence":0.8231346607208252}
```
Your answers may vary slightly.

### Post-Deployment
At this point both the AWS Comprehend classifier and the microservice we are going to invoke to classify emails should be ready to go. Now, you need to setup the last part of this blueprint: the Genesys Cloud components that will process incoming emails, invoke the AWS classifier and then route the email to the appropriate queue. This code can be found [here](../genesys_email_flow).

### Deploy the Genesys Cloud objects
We are now in the last stage of setting up this blueprint. In this last step, we are going to use Genesys Cloud `CX as Code`, the Genesys Cloud Python SDK and Genesys Cloud's Archy tools to deploy all of the Genesys Cloud objects used to handle the email flow in this blueprint. 

Once the pre-requisite tools are installed you need to take the following actions to deploy your flow.

1. Set your credentials and AWS region. 
2. Setup your `CX as Code` flow.auto.tfvars file.
3. Configure your Terraform backend.
4. Initialize Terraform.
5. Apply your Terraform changes.

### Setup your credentials and AWS Regions
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

### Setup your `CX as Code` flow.auto.tfvars file
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

### Configure your Terraform environment

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

### Initialize Terraform
Before you run `Cx as Code` for the first time you need to change to the `components/genesys-email-flow/dev` directory and initialize Terraform by running `terraform init`.

### Apply your Terraform changes
Once `terraform init` has been run, you can create all of the Genesys Cloud objects by running:

`terraform apply --auto-approve`

To teardown all of the objects created by these flows run:

`terraform destroy --auto-approve`

At this point, if you have followed all of the steps properly you should now be able to login into your Genesys org and see all of your queues, integration, data action, email architect flow, email domains and routes created.

**NOTE:  The Terraform scripts attempts to create an email domain route. Normally,Genesys Cloud, by default, only allows two email domain route per organization. If you already have a domain route please use the id of that existing route in this script.  (We are working on data source for email domain routes so we expect this be a temporary issue)  Alternatively, you can contact the Genesys Cloud [CARE](https://help.mypurecloud.com/articles/contact-genesys-cloud-care/) team to request an increase the rate limit be increased for this organization.**

### Post-Deployment
This is the end of the setup for this blueprint. If you followed all three components steps of this blueprint (train the classifier in `components/aws-comprehend`, create the classifier lambda in `aws-classifier-lambda`, and create the Genesys objects in `components/genesys-email-flow`) you should now be able to send email to your classifier and route the email to the appropriate queue. The email that I have been testing will send the user's email to the `IRA` queue:

```
1. Can I rollover my existing 401K to my IRA. 
2. Is an IRA tax-deferred? 
3. Can I make contributions from my IRA to a charitable organization?
4. Am I able to borrow money from my IRA?
5. What is the minimum age I have to be to start taking money out of my IRA?
```

## Additional resources

* [AWS Comprehend](https://aws.amazon.com/comprehend/ "Opens the Amazon AWS Comprehend documentation")
* [AWS API Gateway](https://aws.amazon.com/api-gateway/ "Opens the Amazon AWS API Gateway documentation")
* [AWS Lambda](https://aws.amazon.com/translate/ "Opens the Amazon AWS API Lambda documentation")
* [CX as Code](https://developer.genesys.cloud/api/rest/CX-as-Code/ "Opens the Genesys Cloud documentation on CX as Code")
* [CX as Code Terraform Registry Documentation](https://registry.terraform.io/providers/MyPureCloud/genesyscloud/latest/docs "Opens the CX as Code Terraform Registry documentation")
* [Serverless Framework](https://www.serverless.com/ "Opens the Serverless Framework documentation")