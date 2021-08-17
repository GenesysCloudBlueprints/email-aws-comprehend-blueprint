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

This Genesys Cloud Developer Blueprint explains how to build an inbound email flow in Genesys Cloud that leverages AWS Comprehend's machine learning classifier to classify an email and route the email to a specific queue. The blueprint also demonstrates how to:
- Train the AWS machine learning classifier.
- Use AWS Lambda to build a microservice which invokes the classifier.
- Leverage the AWS API Gateway endpoint.
- Leverage CX as Code configuration tool to deploy all of the required Genesys Cloud objects.

## Scenario
A financial services business has product offerings for 401Ks, IRAs and 529 college savings account. It has three distinct call center groups with agents who specialize in each of these financial service products. When the organization receives emails regarding these product offerings, it requires the emails to be classified and routed to the specific group of agents. If the email cannot be classified, then it must be sent to the general support queue.

## Solution
The solution is to use the Genesys Cloud architect email flow that processes the email and routes it to a specific queue. Genesys Cloud uses AWS Comprehend which uses machine learning classifier to classify the email.

The following illustration shows the components that are involved in the solution:
  1. A customer sends an email to the services. 
  2. The email architect flow uses the Genesys Cloud [data action](https://help.mypurecloud.com/articles/about-the-data-actions-integrations/) to invoke a REST-based service, and sends the email body and subject to the REST service for classification.
  3. [Amazon API gateway](https://aws.amazon.com/api-gateway/), an AWS service, exposes the REST service. The API gateway forwards the request to [AWS Lambda](https://aws.amazon.com/lambda/) to process the classification request. Lambda invokes the [AWS Comprehend](https://aws.amazon.com/comprehend/) classifier endpoint to classify the contents of the email body in real-time. If the Lambda is able to classify the email at a 75% confidence or higher level, it returns one of three categories back to the email flow: 401K, IRA, or 529. Then, the email flow looks up for the queue ID and routes the email to the queue. If the REST classifier cannot reach this level of confidence, the REST service returns an empty string. In this scenario, the call flow will fallback to a general support queue.
   
  4. The flow takes the returned classification, looks up the queue with the same name and then routes the email to the targeted queue.
  5. When an agent receives the email, they will respond to the customer directly from the Genesys Cloud application.


![Email Routing and Classification using AWS Comprehend](images/EmailClassifier.png "Routing and Classification using AWS Comprehend")

## Contents

* [Solution components](#solution-components "Goes to the Solution components section")
* [Requirements](#requirements "Goes to the Requirements section")
* [Implementation steps](#implementation-steps "Goes to the Implementation steps section")
* [Additional resources](#additional-resources "Goes to the Additional resources section")

## Solution components

This solution requires the following components:

* **Genesys Cloud** - A suite of Genesys cloud services for enterprise-grade communications, collaboration, and contact center management. You deploy the architect email flow, integration, data actions, queues and email configuration in Genesys Cloud. 

* **Amazon Comprehend** - An AWS service that uses natural-language processing (NLP) to extract insights about the contents of documents. It develops insights by recognizing the entities, key phrases, language, sentiments, and other common elements in a document. You can train the machine learning model to classify a body of text, create endpoint and expose the endpoint to allow the service to be invoked for real-time analysis.

* **AWS Lambda** - A compute service that lets you run code without provisioning or managing servers. You organize your code into Lambda functions. Lambda runs your function only when needed. You use Amazon API Gateway that routes the request to your Lambda function.

* **Amazon API Gateway** - An AWS service for creating, publishing, maintaining, monitoring, and securing REST, HTTP, and WebSocket APIs at any scale. The gateway exposes the REST endpoint to route the requests to AWS Lambda. 

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
* **Genesys Cloud Platform API Client SDK - Python** - The Python script that calls Archy also uses Platform API Client SDK - Python. For more information about installation instruction, see [Platform API Client SDK - Python](https://developer.genesys.cloud/api/rest/client-libraries/python/ "Opens the Platform API Client SDK - Python page").

### AWS account

* A user account with administrator access and permission to access the following services:
  * AWS Identity and Access Management (IAM)
  * Amazon Comprehend
  * Amazon API Gateway
  * AWS Lambda
* AWS credentials. For more information on setting up your AWS credentials on your local machine see [here](https://docs.aws.amazon.com/sdkref/latest/guide/creds-config-files.html).
* Download and install the AWS CLI. For more information on installing the AWS CLI on your local machine see [here](https://aws.amazon.com/cli/).
* Install the Serverless framework on the machine you are going to run this deploy from. The documentation for downloading and installing the Serverless framework can be found here.
* Install NodeJS on your machine if you do not already have it. For this blueprint, I used version 14.15.0. If you do not have NodeJS on your machine, I recommend using [nvm](https://github.com/nvm-sh/nvm) (Node Version Manager) to install Node.

## Implementation steps

1. [Clone the GitHub repository](#clone-the-github-repository "Goes to the Clone the GitHub repository section")
2. [Train and deploy the AWS Comprehend machine learning classifier](#train-and-deploy-the-aws-comprehend-machine-learning-classifier "Goes to the Train and deploy the AWS Comprehend machine learning classifier section")
3. [Deploy Amazon API Gateway and AWS Lambda](#deploy-amazon-api-gateway-and-aws-lambda "Goes to the Deploy Amazon API Gateway and AWS Lambda section")
4. [Deploy the Genesys Cloud objects](#deploy-the-genesys-cloud-objects "Goes to the Deploy the Genesys Cloud objects section")

### Clone the GitHub repository

Clone the GitHub repository [email-aws-comprehend-blueprint](https://github.com/GenesysCloudBlueprints/email-aws-comprehend-blueprint "Opens the GitHub repository") to your local machine. The `email-aws-comprehend-blueprint/components` folder comprises the necessary scripts and files required for the solution offered by this blueprint. The three major sub-folders are:
  - `components/aws-comprehend`
  - `components/aws-classifier-lambda`
  - `components/genesys-email-flow`

### Train and deploy the AWS Comprehend machine learning classifier

Train an AWS Comprehend machine learning classifier to classify the email messages that are sent from the Genesys Cloud architect email flow. AWS CloudFormation does not have support for the AWS Comprehend API. To train and deploy the classifier, you can either use the AWS management console or the AWS CLI (Command Line Interface). This blueprint uses the AWS CLI.

:::primary
**Note**: In this blueprint, all the AWS CLI commands are executed from the `components/aws-comprehend` directory.
:::

1. Set up the Amazon S3 Bucket and copy the training corpus file, `components/aws-comprehend/comprehendterm.csv`, to the S3 bucket.
   
   ```aws s3api create-bucket --acl private --bucket <<your-bucket-name-here>> --region <<your region>>```
   
   ```aws s3 cp comprehendterms.csv s3://<<your-bucket-name-here>>```

2. In the `components/EmailClassifierBucketBucketAccessRole-Permission.json` file, modify the location of the S3 bucket that you have created. There are two locations in the file that you must update for the S3 storage location, line 10 and line 19 in the JSON file.

3. Create the AWS Identity and Access Management (IAM) role and policy, and attach the role to the policy that the AWS Comprehend classifier will use.

   `aws iam create-role --role-name EmailClassifierBucketAccessRole --assume-role-policy-document file://EmailClassifierBucketAccessRole-TrustPolicy.json`

   `aws iam create-policy --policy-name BucketAccessPolicy --policy-document file://EmailClassifierBucketAccessRole-Permissions.json`

   `aws iam attach-role-policy --policy-arn <<POLICY ARN return from the aws iam create-policy command above>> --role-name EmailClassifierBucketAccessRole`
    :::primary    
    **Note**: Make a note of the `policy-arn` value returned when you execute the command `aws iam create-policy`. You need to use this value in the next step.
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
    Check for the endpoint named `emailclassifier`. When the `Status` attribute is set to `IN_SERVICE`, the classifier is ready for use.  Make a note of the `EndpointArn` attribute for the `emailclassifier` endpoint that you created. 
    This value will need to be set when you are deploying the classifier Lambda later on in the blueprint.

6. Test the classifier using the following command:

    `aws comprehend classify-document --text "Hey I had some questions about what I can use my 529 for in regards to my childrens college tuition. Can I spend the money on things other then tuition" --endpoint-arn <<YOUR EndpointArn>>`

  On a successful setup, you can see a JSON output similar to the following:

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

Deploy the microservice that is used to pass the email body from the Genesys Cloud architect email flow to the AWS Comprehend classifier. To implement the microservice, invoke the AWS Lambda function using the Amazon API Gateway endpoint. The AWS Lambda is built using Typescript and deployed using the [Serverless](https://www.serverless.com/) framework.

1. Create a `.env.dev` file in the `components/aws-classifier-lambda` directory.  Add the two parameters, `CLASSIFIER_ARN` and `CLASSIFIER_CONFIDENCE_THRESHOLD` in the file.
     - Set the `CLASSIFIER_ARN` to the `EndpointArn` value noted in the procedure [Train and deploy the AWS Comprehend machine learning classifier](#train-and-deploy-the-aws-comprehend-machine-learning-classifier "Goes to the Train and deploy the AWS Comprehend machine learning classifier section").
     - Set the `CLASSIFIER_CONFIDENCE_THRESHOLD` parameter value between 0 and 1 which signifies the level of confidence that you want the lambda to have before returning a classification. For example, if `CLASSIFIER_CONFIDENCE_THRESHOLD` is set to 0.75, then the classification returned by the AWS Comprehend classifier must be at or above 75% to return the classification. If the classification falls below this value, the lambda returns an empty string for the classification. 
  
    A sample format of the `.env.dev` file.

    ```
    CLASSIFIER_ARN=arn:aws:comprehend:us-east-1:000000000000:document-classifier-endpoint/emailclassifier-example-only     CLASSIFIER_CONFIDENCE_THRESHOLD=.75
    ```

    You can also retrieve the `EndpointArn` endpoint value using the command `aws comprehend list-endpoints`.

2. Open a terminal and change to the directory `/components/aws-classifier-lambda`. Execute the `npm i` command to download and install all of the third-party packages and dependences.

3. Deploy the Lambda using the `serverless deploy` command. This takes approximately a minute to complete the deployment. Make a note of the `api key` and `endpoints` attributes which are required while deploying the Genesys Cloud flow.

4. Test the lambda using the following command from the terminal:

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

On a successful deployment, you can see the following JSON payload with the classification of the document along with the confidence level.

```json
{
  "QueueName":"IRA",
  "Confidence":0.8231346607208252
}
```

### Deploy the Genesys Cloud objects

We will use Genesys Cloud **CX as Code**, Genesys Cloud Python SDK and Genesys Cloud's Archy tools to deploy all of the Genesys Cloud objects that are used to handle the email flow in this blueprint. 

Do the following actions to deploy the flow:

1. Set your credentials and AWS region 
2. Set up your **CX as Code** `flow.auto.tfvars` file
3. Configure your Terraform backend
4. Initialize Terraform
5. Apply your Terraform changes

### Set up your credentials and AWS Regions

All the Genesys Cloud OAuth2 credentials and AWS region configuration used by **CX as Code** are handled through environment variables. 
The following environment variables need to be set before you run your Terraform configuration:

1. `GENESYSCLOUD_OAUTHCLIENT_ID` - The Genesys Cloud OAuth2 client credential under which the Cx as Code provider will run. For more information about how to setup a Genesys Cloud OAuth2 client credential, see [Create an OAuth client](https://help.mypurecloud.com/articles/create-an-oauth-client/ "Opens the Create an OAuth client page") in the Genesys Cloud Resource Center.

2. `GENESYSCLOUD_OAUTHCLIENT_SECRET` - The Genesys Cloud OAuth2 client secret under which the Cx as Code provider will run.

3. `GENESYSCLOUD_REGION` - The region used by the Genesys Cloud OAuth2 client. You can see the valid regions that can be found in the AWS region field listed in the [Platform API](https://developer.genesys.cloud/api/rest/ "Opens the Platform API page") page in the Genesys Cloud Developer Center.

4. `GENESYSCLOUD_API_REGION` - The Genesys Cloud API endpoint to which the Genesys Cloud SDK will connect. Valid values can be found in the `API SERVER` field listed in the [Platform API](https://developer.genesys.cloud/api/rest/ "Opens the Platform API page") page in the Genesys Cloud Developer Center.

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

### Set up your CX as Code flow.auto.tfvars file

All application configuration for this flow is defined in the `components/genesys-email-flow/dev/flow.auto.tfvars` file. Configure the parameters in this file to the values specific to your organization. The parameters configured in this file include:

- `genesys_email_domain` - A globally unique name for your Genesys Cloud email domain name. If you choose a name that already exists, then the execution of the **CX as Code** scripts fail.

- `genesys_email_domain_region` - The suffix for the email domain. Valid values are based on the AWS region. Valid values include:
  ```
      - US East -------> mypurecloud.com
      - US West --------> pure.cloud
      - Canada  --------> pure.cloud
      - Europe(Ireland)   --------> mypurecloud.ie
      - Europe(London)    --------> pure.cloud
      - Europe(Frankfurt) --------> mypurecloud.de
      - Asia(Mumbai)       --------> pure.cloud
      - Asia(Tokyo)       --------> mypurecloud.jp
      - Asia(Seoul)       --------> pure.cloud
      - Asia(Sydney)      --------> mypurecloud.au
   ```
   **Note**: Your `genesys_email_domain_region` must be in the same region as your Genesys Cloud organization.

   This script creates an email route called `support` to which the users can send emails. For example, if you set your `genesys_email_domain` to `devengagedev` and `genesys_email_domain_region` to `pure.cloud`, then the `Cx as Code` script creates an email route `support@devengagedev.pure.cloud`. Any emails sent to this address will be processed by the email architect flow.

3. `classifier_url` - The endpoint used to invoke the classifier. You must use the endpoint that you created while setting up the `components/aws-comprehend` part of this blueprint.

4. `classifier_api_key`. The API key you needed to invoke the endpoint defined in step #3 above. The api key you set here should be the API key created when setting up the [AWS Comprehend](#train-and-deploy-the-aws-comprehend-machine-learning-classifier "Opens the Train and deploy the AWS Comprehend learning classifier section").

### Configure the Terraform environment

Terraform requires a backend for storing state. In this blueprint, the backend is configured in a file separate from the project files. Modify the `components/genesys-email-flow/dev/main.tf` file to point where you want create the backend file. Modify the following section of this code:

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

Before you run **Cx as Code** for the first time, change to the `components/genesys-email-flow/dev` directory and initialize Terraform using the command `terraform init`.

### Apply your Terraform changes

To create all of the Genesys Cloud objects, execute the following command:

`terraform apply --auto-approve`

To teardown all of the objects created by these flows, run the following command:

`terraform destroy --auto-approve`

You can now log into your Genesys Cloud org and see all the queues, integration, data action, email architect flow, email domains, and routes that are created.


**Note**:  The Terraform scripts attempts to create an email domain route. By default, Genesys Cloud only allows two email domain route per organization. If you already have a domain route, then use the email ID of that existing route in this script. Alternatively, you can also contact the Genesys Cloud [CARE](https://help.mypurecloud.com/articles/contact-genesys-cloud-care/) team and make a request to increase the rate limit for the organization.

### Test the deployment

To check the set up success, you can send email to your classifier and route the email to the appropriate queuq. You can send the email with any of the following questions for IRA:

- Can I rollover my existing 401K to my IRA. 
- Is an IRA tax-deferred? 
- Can I make contributions from my IRA to a charitable organization?
- Am I able to borrow money from my IRA?
- What is the minimum age I have to be to start taking money out of my IRA?

The emails with request for IRA information will be sent to the IRA queue.


## Additional resources

* [AWS Comprehend](https://aws.amazon.com/comprehend/ "Opens the Amazon AWS Comprehend documentation")
* [AWS API Gateway](https://aws.amazon.com/api-gateway/ "Opens the Amazon AWS API Gateway documentation")
* [AWS Lambda](https://aws.amazon.com/translate/ "Opens the Amazon AWS API Lambda documentation")
* [CX as Code](https://developer.genesys.cloud/api/rest/CX-as-Code/ "Opens the Genesys Cloud documentation on CX as Code")
* [CX as Code Terraform Registry Documentation](https://registry.terraform.io/providers/MyPureCloud/genesyscloud/latest/docs "Opens the CX as Code Terraform Registry documentation")
* [Serverless Framework](https://www.serverless.com/ "Opens the Serverless Framework documentation")