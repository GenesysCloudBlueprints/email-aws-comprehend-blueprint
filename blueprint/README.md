# Improve email routing with Amazon Comprehend's Natural Language Processing 

View the full [Improve email routing with Amazon Comprehend  article](https://developer.mypurecloud.com/blueprints/email-aws-comprehend-blueprint/) on the Genesys Cloud Developer Center.

This Genesys Cloud Developer Blueprint explains how to use Amazon Comprehend's Natural Language Processing (NLP) to classify inbound emails so they can be routed to a specific queue.

This blueprint also demonstrates how to:
* Use machine learning to train the Amazon Comprehend classifier
* Use AWS Lambda to build a microservice, which invokes the Amazon Comprehend classifier
* Use the Amazon API Gateway to expose a the Amazon Comprehend REST endpoint
* Use the CX as Code configuration tool to deploy all of the required Genesys Cloud objects including the Architect inbound email flow

![Email Routing and Classification using Genesys Cloud and Amazon Comprehend](images/EmailClassifier.png "Routing and Classification using AWS Comprehend")
<<<<<<< HEAD
=======

## Contents

* [Solution components](#solution-components "Goes to the Solution components section")
* [Requirements](#requirements "Goes to the Requirements section")
* [Implementation steps](#implementation-steps "Goes to the Implementation steps section")
* [Additional resources](#additional-resources "Goes to the Additional resources section")

## Solution components

This solution requires the following components:

* **Genesys Cloud** - A suite of Genesys cloud services for enterprise-grade communications, collaboration, and contact center management. You deploy the Architect email flow, integration, data actions, queues, and email configuration in Genesys Cloud. 

* **Amazon Comprehend** - An AWS service that uses natural-language processing (NLP) to analyze and interpret the content of text documents. In this solution, you use AWS Comprehend to train a machine learning model that classifies the contents of inbound emails in real-time. You can train the machine learning model to classify a body of text, create an endpoint, and expose the endpoint to invoke the service for real-time analysis.

* **AWS Lambda** - A serverless computing service for running code without creating or maintaining the underlying infrastructure. In this solution, AWS Lambda processes requests that come through the API Gateway and calls the Amazon Comprehend endpoint.

* **Amazon API Gateway** - An AWS service for using APIs in a secure and scalable environment. In this solution, the API Gateway exposes a REST endpoint that is protected by an API key. Requests that comes to the API Gateway are forwarded to an AWS Lambda.

* **AWS Command Line Interface (CLI)** - A unified tool to manage your AWS services from the command line.

## Prerequisites

### Specialized knowledge

* Administrator-level knowledge of Genesys Cloud
* AWS Cloud Practitioner-level knowledge of AWS IAM, Amazon Comprehend, Amazon API Gateway, AWS Lambda, and the AWS SDK for JavaScript
* Experience using the Genesys Cloud Platform API and Genesys Cloud Python SDK

### Genesys Cloud account

* A Genesys Cloud license. For more information, see [Genesys Cloud Pricing](https://www.genesys.com/pricing "Opens the Genesys Cloud pricing page") in the Genesys website.
* Master Admin role. For more information, see [Roles and permissions overview](https://help.mypurecloud.com/?p=24360 "Opens the Roles and permissions overview article") in the Genesys Cloud Resource Center.
* **Terraform** - Install the latest Terraform binary. For more information about installing Terraform, see [Download Terraform](https://www.terraform.io/downloads.html "Opens the Download Terraform page") in the Terraform website. 
* **Archy** - Install the latest Genesys Cloud Archy import and export tool. For more information about the instructions for installing Archy, see [Archy Installation](https://developer.genesys.cloud/devapps/archy/ "Opens the Archy Installation page") in the Genesys Cloud Developer Center.
* **Python 3.7** - Install Python 3.7 or later version as the Terraform flow wrappers an Archy call using Python 3.7.
* **Genesys Cloud Platform API Client SDK - Python** - The Python script that calls Archy also uses Platform API Client SDK - Python. For more information about the installation instruction, see [Platform API Client SDK - Python](https://developer.genesys.cloud/api/rest/client-libraries/python/ "Opens the Platform API Client SDK - Python page") in the Genesys Cloud Developer Center.

### AWS account

* A user account with administrator access and permission to access the following services:
  * AWS Identity and Access Management (IAM)
  * Amazon Comprehend
  * Amazon API Gateway
  * AWS Lambda
* AWS credentials. For more information about setting up your AWS credentials on your local machine, see [About credential providers](https://docs.aws.amazon.com/sdkref/latest/guide/creds-config-files.html "Opens the About credential providers page") in AWS documentation.
* Download and install the AWS CLI. For more information about installing the AWS CLI on your local machine, see [About credential providers](https://aws.amazon.com/cli/ "Opens the About credential providers page") in the AWS documentation.
* Install the Serverless Framework on the local machine that you are going to run the deployment. For more information about downloading and installing the Serverless Framework, see [Get started with Serverless Framework](https://www.serverless.com/framework/docs/getting-started/ "Opens the Serverless Framework page") in the Serverless Framework documentation.
* [Install NodeJS](https://github.com/nvm-sh/nvm "Opens the NodeJS GitHub repository"). This blueprint recommends NodeJS version 14.15.0.

## Implementation steps

1. [Clone the GitHub repository](#clone-the-github-repository "Goes to the Clone the GitHub repository section")
2. [Train and deploy the AWS Comprehend machine learning classifier](#train-and-deploy-the-aws-comprehend-machine-learning-classifier "Goes to the Train and deploy the AWS Comprehend machine learning classifier section")
3. [Deploy Amazon API Gateway and AWS Lambda](#deploy-amazon-api-gateway-and-aws-lambda "Goes to the Deploy Amazon API Gateway and AWS Lambda section")
4. [Deploy the Genesys Cloud objects](#deploy-the-genesys-cloud-objects "Goes to the Deploy the Genesys Cloud objects section")

### Clone the GitHub repository

Clone the GitHub repository [email-aws-comprehend-blueprint](https://github.com/GenesysCloudBlueprints/email-aws-comprehend-blueprint "Opens the GitHub repository") to your local machine. The `email-aws-comprehend-blueprint/components` folder includes the necessary scripts and files required for the solution offered by this blueprint. The three major subfolders are:
  - `components/aws-comprehend`
  - `components/aws-classifier-lambda`
  - `components/genesys-email-flow`

### Train and deploy the AWS Comprehend machine learning classifier

To classify the email messages that are sent from the Genesys Cloud Architect email flow, train an AWS Comprehend machine learning classifier. AWS CloudFormation does not have support for the AWS Comprehend API. To train and deploy the classifier, you can either use the AWS management console or the AWS CLI (Command Line Interface). This blueprint uses the AWS CLI.

:::primary
**Note**: In this blueprint, all the AWS CLI commands are run from the `components/aws-comprehend` directory.
:::

1. Set up the Amazon S3 Bucket and copy the training corpus file, `components/aws-comprehend/comprehendterm.csv`, to the S3 bucket.
   
   ```aws s3api create-bucket --acl private --bucket <<your-bucket-name-here>> --region <<your region>>```
   
   ```aws s3 cp comprehendterms.csv s3://<<your-bucket-name-here>>```

2. In the `components/EmailClassifierBucketBucketAccessRole-Permission.json` file, modify the location of the S3 bucket that you have created. There are two locations in the file that you must update for the S3 storage location, line 10 and line 19 in the JSON file.

3. Create the AWS Identity and Access Management (IAM) role and policy, and attach the role to the policy that the AWS Comprehend classifier uses.

   `aws iam create-role --role-name EmailClassifierBucketAccessRole --assume-role-policy-document file://EmailClassifierBucketAccessRole-TrustPolicy.json`

   `aws iam create-policy --policy-name BucketAccessPolicy --policy-document file://EmailClassifierBucketAccessRole-Permissions.json`

   `aws iam attach-role-policy --policy-arn <<POLICY ARN return from the aws iam create-policy command above>> --role-name EmailClassifierBucketAccessRole`
    :::primary    
    **Note**: Make a note of the `policy-arn` value returned when you run the command `aws iam create-policy`. You need to use this value in the next step.
    :::
4. Train the AWS Comprehend document classifier.
   
    `aws comprehend create-document-classifier --document-classifier-name FinancialServices --data-access-role-arn <<ARN FROM STEP 2 HERE>> --input-data-config S3Uri=s3://<<YOUR BUCKET NAME HERE>> --language-code en` 
     :::primary
     **Note**: It takes several minutes for the AWS Comprehend to complete the training of the classifier. You can monitor the progress and proceed to the next step only after the training is completed. You can check the status of the classifier using the command:
     
     `aws comprehend list-document-classifiers` 
     :::
    When the `Status` attribute returns `TRAINED`, your classifier training is complete. Make a note of the `DocumentClassifierArn` value to use in the next step.

5. Create the real-time document classifier endpoint.
    
    `aws comprehend create-endpoint --endpoint-name emailclassifier --model-arn <<YOUR DocumentClassifierArn here>> --desired-inference-units 1`
    :::primary
    **Note**: It takes several minutes for the real-time classifier endpoint to become active. You can monitor the status of the endpoint using the command:
    
    `aws comprehend list-endpoints` 
    :::

    Check for the endpoint named `emailclassifier`. When the `Status` attribute is set to `IN_SERVICE`, the classifier is ready for use. Make a note of the `EndpointArn` attribute for the `emailclassifier` endpoint that you have created. 
    This value will need to be set when you are deploying the classifier Lambda later on in the blueprint.

6. Test the classifier using the following command:

    `aws comprehend classify-document --text "Hey I had some questions about what I can use my 529 for in regards to my childrens college tuition. Can I spend the money on things other then tuition" --endpoint-arn <<YOUR EndpointArn>>`

  A JSON output similar to the following displays on successful deployment:

  ```json
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
  ```

### Deploy the serverless microservice using AWS Lambda and Amazon API Gateway

Deploy the microservice that is used to pass the email body from the Genesys Cloud Architect email flow to the AWS Comprehend classifier. To implement the microservice, invoke the AWS Lambda function using the Amazon API Gateway endpoint. The AWS Lambda is built using Typescript and deployed using the [Serverless](https://www.serverless.com/) framework.

1. Create a `.env.dev` file in the `components/aws-classifier-lambda` directory. Add the two parameters, `CLASSIFIER_ARN` and `CLASSIFIER_CONFIDENCE_THRESHOLD` in the file.
     - Set the `CLASSIFIER_ARN` to the `EndpointArn` value noted in the procedure [Train and deploy the AWS Comprehend machine learning classifier](#train-and-deploy-the-aws-comprehend-machine-learning-classifier "Goes to the Train and deploy the AWS Comprehend machine learning classifier section").
     - Set the `CLASSIFIER_CONFIDENCE_THRESHOLD` parameter value between 0 and 1 which signifies the level of confidence that you want the lambda to have before returning a classification. For example, if `CLASSIFIER_CONFIDENCE_THRESHOLD` is set to 0.75, then the classification returned by the AWS Comprehend classifier must be at or above 75 percent to return the classification. If the classification falls below this value, the lambda returns an empty string for the classification. 
  
    A sample format of the `.env.dev` file.

    ```
    CLASSIFIER_ARN=arn:aws:comprehend:us-east-1:000000000000:document-classifier-endpoint/emailclassifier-example-only     CLASSIFIER_CONFIDENCE_THRESHOLD=.75
    ```

    You can also retrieve the `EndpointArn` endpoint value using the command `aws comprehend list-endpoints`.

2. Open a command prompt and change to the directory `/components/aws-classifier-lambda`.
3. To download and install all the third-party packages and dependencies, run the following command:

    `npm i`

4. Deploy the Lambda function using the command: 
   
   `serverless deploy`

    The deployment takes approximately a minute to complete. Make a note of the `api key` and `endpoints` attributes which are required while deploying the Genesys Cloud flow.

5. Test the Lambda function using the following command:

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

A successful deployment displays the following JSON payload that lists the classification of the document along with the confidence level.

```json
{
  "QueueName":"IRA",
  "Confidence":0.8231346607208252
}
```

### Deploy the Genesys Cloud objects

We use Genesys Cloud CX as Code, Genesys Cloud Python SDK, and Genesys Cloud's Archy tools to deploy all the Genesys Cloud objects that are used to handle the email flow in this blueprint. 

To deploy the email flow:

1. [Set up your credentials and AWS regions](#set-up-your-credentials-and-aws-regions "Goes to the Set up your credentials and AWS regions section")
2. [Set the CX as Code `flow.auto.tfvars` file](#set-the-cx-as-code-flowautotfvars-file "Goes to the Set the CX as Code `flow.auto.tfvars` file section")
3. [Configure your Terraform backend](#configure-the-terraform-environment "Goes to the Configure your Terraform backend section")
4. Initialize Terraform
5. Apply your Terraform changes

### Set up your credentials and AWS regions

All the Genesys Cloud OAuth2 credentials and AWS region configuration used by CX as Code are handled through environment variables. Set the following environment variables before you run your Terraform configuration:

1. `GENESYSCLOUD_OAUTHCLIENT_ID` - The Genesys Cloud OAuth2 client credential under which the CX as Code provider runs. For more information about how to set up a Genesys Cloud OAuth2 client credential, see [Create an OAuth client](https://help.mypurecloud.com/articles/create-an-oauth-client/ "Opens the Create an OAuth client page") in the Genesys Cloud Resource Center.

2. `GENESYSCLOUD_OAUTHCLIENT_SECRET` - The Genesys Cloud OAuth2 client secret under which the CX as Code provider runs.

3. `GENESYSCLOUD_REGION` - The region used by the Genesys Cloud OAuth2 client. The [Platform API](https://developer.genesys.cloud/api/rest/ "Opens the Platform API page") page in the Genesys Cloud Developer Center lists the Genesys Cloud regions and the corresponding AWS regions.

4. `GENESYSCLOUD_API_REGION` - The Genesys Cloud API endpoint to which the Genesys Cloud SDK connects. You can see the valid values in the `API SERVER` field listed in the [Platform API](https://developer.genesys.cloud/api/rest/ "Opens the Platform API page") page in the Genesys Cloud Developer Center.

5. `GENESYSCLOUD_ARCHY_REGION` - The Genesys Cloud domain name that Archy uses to resolve the Genesys Cloud AWS region to which it connects. Valid locations include: 
```
    - apne2.pure.cloud
    - aps1.pure.cloud
    - cac1.pure.cloud
    - euw2.pure.cloud
    - mypurecloud.com
    - mypurecloud.com.au
    - mypurecloud.de
    - mypurecloud.ie
    - mypurecloud.jp
    - usw2.pure.cloud
  ```                             

### Set the CX as Code flow.auto.tfvars file

All application configuration for this email flow is defined in the `components/genesys-email-flow/dev/flow.auto.tfvars` file. Configure the parameters in this file to the values specific to your organization. The parameters configured in this file include:

- `genesys_email_domain` - A globally unique name for your Genesys Cloud email domain name. If you choose a name that exists, then the execution of the CX as Code scripts fail.

- `genesys_email_domain_region` - The suffix for the email domain. Valid values are based on the AWS region. Valid values include:

  | Region            	| Domain suffix    	|
  |--------------------	|-----------------	|
  | US East             | mypurecloud.com   |
  | US West            	| pure.cloud      	|
  | Canada             	| pure.cloud      	|
  | Europe (Ireland)   	| mypurecloud.ie  	|
  | Europe (London)    	| pure.cloud      	|
  | Europe (Frankfurt) 	| mypurecloud.de  	|
  | Asia (Mumbai)      	| pure.cloud      	|
  | Asia (Tokyo)       	| mypurecloud.jp  	|
  | Asia (Seoul)       	| pure.cloud      	|
  | Asia (Sydney)      	| mypurecloud.au  	|
  
   :::primary
   **Note**: Your `genesys_email_domain_region` must be in the same region as your Genesys Cloud organization.
   :::

   This script creates an email route called `support` to which the users can send emails. For example, if you set your `genesys_email_domain` to `devengagedev` and `genesys_email_domain_region` to `pure.cloud`, then the `CX as Code` script creates an email route `support@devengagedev.pure.cloud`. Any emails sent to this address are processed by the email flow.

1. `classifier_url` - The endpoint used to invoke the classifier. Use the endpoint that you created while setting up the `components/aws-comprehend` part of this blueprint.

2. `classifier_api_key`. The API key you needed to invoke the endpoint defined in step #3 above. The api key you set here should be the API key created when setting up the [AWS Comprehend](#train-and-deploy-the-aws-comprehend-machine-learning-classifier "Opens the Train and deploy the AWS Comprehend learning classifier section").

### Configure the Terraform environment

Terraform requires a backend for storing the state. In this blueprint, the backend is configured in a file separate from the project files. Modify the backend path in the `components/genesys-email-flow/dev/main.tf` file to the location where you want to create the backend file. Modify the following section of this code:

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

Before you run CX as Code for the first time, change to the `components/genesys-email-flow/dev` directory and initialize Terraform:

`terraform init`

### Apply your Terraform changes

To create all the Genesys Cloud objects, run the following command:

`terraform apply --auto-approve`

To teardown all the objects created by these flows, run the following command:

`terraform destroy --auto-approve`

You can now log in to your Genesys Cloud org and view all the queues, integration, data action, email flow, email domains, and routes that are created.
:::primary
**Note**:  The Terraform scripts attempt to create an email domain route. By default, Genesys Cloud only allows two email domain route per organization. If you already have a domain route, then use the email ID of that existing route in this script. Alternatively, you can also contact the [Genesys Cloud Customer Care](https://help.mypurecloud.com/articles/contact-genesys-cloud-care/ "Opens the Genesys Cloud Customer Care article") team and make a request to increase the rate limit for the organization.
:::

### Test the deployment

To check the setup success, you can send an email to your classifier and route the email to the appropriate queue. For example, you can send an email with any of the following questions about IRA:

- Can I rollover my existing 401K to my IRA. 
- Is an IRA tax-deferred? 
- Can I make contributions from my IRA to a charitable organization?
- Am I able to borrow money from my IRA?
- What is the minimum age I have to be to start taking money out of my IRA?

The email with a request for IRA information is sent to the IRA queue.

## Additional resources

* [Amazon Comprehend](https://aws.amazon.com/comprehend/ "Opens the Amazon Comprehend page") in the Amazon featured services
* [Amazon API Gateway](https://aws.amazon.com/api-gateway/ "Opens the Amazon API Gateway page") in the Amazon featured services
* [AWS Lambda](https://aws.amazon.com/translate/ "Opens the Amazon AWS Lambda page") in the Amazon featured services
* [CX as Code](https://developer.genesys.cloud/api/rest/CX-as-Code/ "Opens the CX as Code page") in the Genesys Cloud Developer Center
* [Terraform Registry Documentation](https://registry.terraform.io/providers/MyPureCloud/genesyscloud/latest/docs "Opens the Genesys Cloud provider page") in the Terraform documentation
* [Serverless Framework](https://www.serverless.com/ "Opens the Serverless Framework page") in the Serverless Framework website
>>>>>>> 26802ab5ebb59bb0afec22e7b8218b060cd363d7
