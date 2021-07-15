After the AWS classifier has been setup, we need to deploy the microservice that will be used to pass the email body from the Genesys Cloud architect email flow to the AWS classifier. To implement this microservice, we are going to deploy an AWS lambda fronted by an AWS API gateway endpoint.

The lambda in question was built using Typescript and is built and deployed using the [Serverless](https://www.serverless.com/) framework.

# Pre-Requisites
Before beginning this part of the tutorial please make sure you have done the following steps:

1. Have a valid AWS account that is able to access and deploy AWS API Gateway and AWS Lambda. 

2. Have a set of AWS credentials (eg. client id and secret). For more information on setting up your AWS credentials on your local machine see [here](https://docs.aws.amazon.com/sdkref/latest/guide/creds-config-files.html).

3. Install the Serverless framework on the machine you are going to run this deploy from. The documentation for downloading and installing the Serverless framework can be found [here](https://www.serverless.com/framework/docs/getting-started/).

4. Install NodeJS on your machine if you do not already have it. For this blueprint, I used version 14.15.0. If you do not have NodeJS on your machine, I recommend using [nvm](https://github.com/nvm-sh/nvm) (Node Version Manager) to install Node.

# Deployment Steps

1. **Create a `.env.dev` file in the `components/aws-classifier-lambda` directory.  This file should contain 2 values: `CLASSIFIER_ARN` and `CLASSIFIER_CONFIDENCE_THRESHOLD`.  The `CLASSIFIER_ARN` should be set to `EndpointArn` created when you trained the classifier (reference the `components/aws-comprehend` on how to train the classifier). The `CLASSIFIER_CONFIDENCE_THRESHOLD` is a value between 0 and 1 that signifies the level of confidence you want the lambda to have before returning a classification. For example, if `CLASSIFIER_CONFIDENCE_THRESHOLD` equals .75, that means the classification returned by the AWS Comprehend classifier must be at or above 75% to return the classification. If the classification falls below this value, the lambda will return an empty string for the classification.  Shown below is an example `.env.dev` file.

```
CLASSIFIER_ARN=arn:aws:comprehend:us-east-1:000000000000:document-classifier-endpoint/emailclassifier-example-only
CLASSIFIER_CONFIDENCE_THRESHOLD=.75
```

If you did not write down the `EndpointArn` you can use the AWS cli command: `aws comprehend list-endpoints` command to retrieve the endpoint. The `EndpointArn` will be in the returned data.

2. **Open a command-line window and in the `email-aws-comprehend-blueprint/components/aws-classifier-lambda` directory run the `npm i` command to download and install all of the third-party packages and dependences**.  

3. **Deploy the lambda using `sls deploy` command.** This will take about a minute to deploy and when the lambda is deploy there are two important pieces of information that need to be captured for using when deploying the Genesys Cloud flow:  `api key` and `endpoints`.

4. **Test the lambda**.  Once the lambda is complete you can test it from the command line by issuing the following command:

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

# Post-Deployment
At this point both the AWS Comprehend classifier and the microservice we are going to invoke to classify emails should be ready to go. Now, you need to setup the last part of this blueprint: the Genesys Cloud components that will process incoming emails, invoke the AWS classifier and then route the email to the appropriate queue. This code can be found [here](../genesys_email_flow).
