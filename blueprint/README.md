---
title: Genesys Cloud Email Routing and Classification using AWS Comprehend
author: john.carnell
indextype: blueprint
icon: blueprint
image: images/EmailClassiiferNoNumber.png
category: 5
summary: |
  This Genesys Cloud Developer Blueprint provides instructions for building a Genesys Cloud email flow that leverages an AWS Comprehend machine learning classifier to classify an email and map the email to a routing queue specific to that email classification. 
---

This Genesys Cloud Developer Blueprint provides instructions for building a Genesys Cloud email flow that leverages an AWS Comprehend machine learning classifier to classify an email and map the email to a routing queue specific to that email classification. 

In this blueprint we will demonstrate how to train a AWS Machine Learning classifier, leverage AWS Api Gateway and Lambda to build a microservice to provide email classification, and leverage `CX as Code` to deploy all of the Genesys Cloud objects needed to build and support this email flow. For this blueprint, we are going to pretend
that we are building a solution for a financial services company that has product offerings for 401Ks, IRAs and 529 college savings account. The financial services group has  4 distinct call center groups with agents who specialize in each of these financial service products.  When an email is sent to the company, the company wants to have a Genesys Cloud architect email flow process the email and then use a machine learning model to classify the email. Based on the email contents, the email should be routed to a queue specific to the particular topic area. If the machine learning classifier is unable classify the incoming email, the financial services company wants to send the email to a general support queue.

For this blueprint we are going to use AWS Comprehend to perform the machine learning classification. The diagram below shows all of the components involved along with the general flow of activity involved in the solution.

![Email Routing and Classification using AWS Comprehend](images/EmailClassifier.png "Routing and Classification using AWS Comprehend")

The following actions take place in the diagram above:

1. A customer sends an email to an email address backed by a Genesys Cloud [architect email flow](https://help.mypurecloud.com/articles/inbound-email-flows/).

2. When an email is received the email architect flow will use a Genesys Cloud [data action](https://help.mypurecloud.com/articles/about-the-data-actions-integrations/) to invoke a REST-based service and send the email body and subject to the REST service for classification.

3. A REST service will be expose by [AWS API gateway](https://aws.amazon.com/api-gateway/). The API gateway will forward the request onto an [AWS Lambda](https://aws.amazon.com/lambda/) to process the classification request.  This lambda will be used to invoke an [AWS Comprehend](https://aws.amazon.com/comprehend/) machine learning classifier to classify the email.  If the lambda is able to classify the email at a 75% confidence or higher level, it will return one of categories back to the flow: `401K`, `IRA`, or `529`. The email flow will then lookup the queue and route the email to the queue. If the REST classifier can not reach this level of confidence, the REST service will return an empty string.  In the case, the call flow will fallback to a general support queue.

4. The flow takes the returned classification, looks up the queue with the same name and then routes the email to the targeted queue.

5. When an agent receives the email, they will respond to the customer directly from within the Genesys Cloud application.


* [Solution components](#solution-components "Goes to the Solution components section")
* [Requirements](#requirements "Goes to the Requirements section")
* [Implementation steps](#implementation-steps "Goes to the Implementation steps section")
* [Additional resources](#additional-resources "Goes to the Additional resources section")

## Solution components

This solution requires the following components:

* **Genesys Cloud** - A suite of Genesys cloud services for enterprise-grade communications, collaboration, and contact center management. You deploy the architect email flow, integration, data actions, queues and email configuration in Genesys Cloud. 

* **AWS Comprehend** - AWS Comprehend is an an AWS service that lets your train a machine learning model to classify a body of text. Using AWS Comprehend requires you to first train a classification model and then expose AWS endpoint to allow the service to be invoke for real-time analysis

* **AWS API Gateway and AWS Lambda** - The AWS API gateway is used to exposed a REST endpoint that is protected by an API key.  Requests coming into the API gateway are forwarded to an AWS Lambda (written in Typescript for this example) that will process the request and call the AWS Comprehend endpoint classified defined in the previous bullet.

## Requirements

### Specialized knowledge

* Administrator-level knowledge of Genesys Cloud
* AWS Cloud Practitioner-level knowledge of AWS IAM, AWS Comprehend, and AWS API Gateway, AWS Lambda, and the AWS JavaScript SDK
* Experience using the Genesys Cloud Platform API and Genesys Cloud Python SDK

### Genesys Cloud account

* A Genesys Cloud license. For more information, see [Genesys Cloud Pricing](https://www.genesys.com/pricing "Opens the Genesys Cloud pricing page") in the Genesys website.
* The Master Admin role. For more information, see [Roles and permissions overview](https://help.mypurecloud.com/?p=24360 "Opens the Roles and permissions overview article") in the Genesys Cloud Resource Center.

### AWS account

* A user account with Administrator Access permission and full access to the following services:
  * IAM service
  * AWS Comprehend service
  * AWS API gateway service
  * AWS Lambda service

## Implementation steps


1. **Clone the [email-aws-comprehend-blueprint](https://github.com/GenesysCloudBlueprints/email-aws-comprehend-blueprint "Opens the email-aws-comprehend-blueprint repository in GitHub")**.

2. **Train the AWS Comprehend machine learning model**. To train and deploy the AWS Comprehend model, you need leverage the AWS command-line tool. Detailed instructions can for performing this step can be found [here](/components/aws-comprehend). 

3. **Deploy API Gateway and the AWS Lambda**. The API Gateway and the AWS Lambda are built using the [Serverless](https://www.serverless.com/) framework. Detailed instructions for performing this step can be found [here](/components/aws-classifier-lambda).

4. **Deploy the Genesys Cloud objects**.  The Genesys Cloud objects are deployed using [CX as Code](https://developer.genesys.cloud/api/rest/CX-as-Code/). Detailed 
instructions for perform this step can be found [here](/genesys-email-flow).

## Additional resources

* [AWS Comprehend](https://aws.amazon.com/comprehend/ "Opens the Amazon AWS Comprehend documentation")
* [AWS API Gateway](https://aws.amazon.com/api-gateway/ "Opens the Amazon AWS API Gateway documentation")
* [AWS Lambda](https://aws.amazon.com/translate/ "Opens the Amazon AWS API Lambda documentation")
* [CX as Code](https://developer.genesys.cloud/api/rest/CX-as-Code/ "Opens the Genesys Cloud documentation on CX as Code")
* [CX as Code Terraform Registry Documentation](https://registry.terraform.io/providers/MyPureCloud/genesyscloud/latest/docs "Opens the CX as Code Terraform Registry documentation")
* [Serverless Framework](https://www.serverless.com/ "Opens the Serverless Framework documentation")