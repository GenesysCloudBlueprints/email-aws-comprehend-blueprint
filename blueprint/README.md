# Improve email routing with Amazon Comprehend's Natural Language Processing 

View the full [Improve email routing with Amazon Comprehend  article](https://developer.mypurecloud.com/blueprints/email-aws-comprehend-blueprint/) on the Genesys Cloud Developer Center.

This Genesys Cloud Developer Blueprint explains how to use Amazon Comprehend's Natural Language Processing (NLP) to classify inbound emails so they can be routed to a specific queue.

This blueprint also demonstrates how to:
* Use machine learning to train the Amazon Comprehend classifier
* Use AWS Lambda to build a microservice, which invokes the Amazon Comprehend classifier
* Use the Amazon API Gateway to expose a the Amazon Comprehend REST endpoint
* Use the CX as Code configuration tool to deploy all of the required Genesys Cloud objects including the Architect inbound email flow

![Email Routing and Classification using Genesys Cloud and Amazon Comprehend](images/EmailClassifier.png "Routing and Classification using AWS Comprehend")
