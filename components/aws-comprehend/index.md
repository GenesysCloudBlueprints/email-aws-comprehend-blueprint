This guide will walk you through how to train an AWS Comprehend machine learning classifier to classify email messages sent from this blueprints Genesys Cloud email flow.  AWS Cloudformation does not have support for the AWS Comprehend API at this point.  For the training and deploying the classifier, you will need to use AWS management console or the AWS command line tool to train the classifier. For this blueprint, we will use the AWS CLI.

# Pre-Requisites
Before beginning this part of the tutorial please make sure you have done the following steps:

1. Have a valid AWS account that is able to access and deploy AWS comprehend. 
2. Have a set of AWS credentials (eg. client id and secret). For more information on setting up your AWS credentials on your local machine see [here](https://docs.aws.amazon.com/sdkref/latest/guide/creds-config-files.html).
3. Download and install the AWS Command Line Interface tool.  For more information on installing the AWS CLI on your local machine see [here](https://aws.amazon.com/cli/).


# Deployment Steps

In order to deploy train and deploy the classifier you need to take the following steps.

Note:  All AWS CLI commands are assumed to be run from the `components/aws-comprehend` directory.

1. **Setup the S3 Bucket and copy the training corpus (comprehendterm.csv) to the created S3 bucket** 
   `aws s3api create-bucket --acl private --bucket <<your-bucket-name-here>> --region <<Your region>>` 
   
   `aws s3 cp comprehendterms.csv s3://<<your-bucket-name-here>>`

2. **Define the IAM Role and policy the AWS Comprehend Classifier will use.** 
   `aws iam create-role --role-name EmailClassifierBucketAccessRole --assume-role-policy-document file://EmailClassifierBucketAccessRole-TrustPolicy.json`
   
   `aws iam put-role-policy --role-name EmailClassifierBucketAccessRole --policy-name BucketAccessPolicy --policy-document file://EmailClassifierBucketAccessRole-Permissions.json`
        
    **NOTE**: The `Arn` returned on the `aws iam create-role` call.  You are going to need it for the `aws create-document-classifier` in the next step.

3. **Train the AWS Comprehend document classifier.**
    `aws comprehend create-document-classifier --document-classifier-name FinancialServices --data-access-role-arn <<ARN FROM STEP 2 HERE>> --input-data-config S3Uri=s3://<<YOUR BUCKET NAME HERE>> --language-code en` 

     **NOTE**:  It can take several minutes before AWS completes the training of the classifier. You need to monitor the progress and only run step 4 after the classifier training is completed. The AWS CLI command to see your classifier status: 
     
     `aws comprehend list-document-classifiers`  
     
    Once your classifier is trained to note of the `DocumentClassifierArn` value. This value will be used in step below.

4. **Create the real-time document classifier endpoint.**
    
    `aws comprehend create-endpoint --endpoint-name emailclassifier --model-arn <<YOUR DocumentClassifierArn>> here --desired-inference-units 1`

    **NOTE**: It can take several minutes for the real-time classifier endpoint to become active. You can monitor the status of the endpoint by calling:
    
    `aws-list-endpoints` 
    
    Look for the your endpoint name (e.g. emailclassifier). When the `Status` is set to `IN_SERVICE` the classifier is ready to be used.
    Take note of the `EndpointArn` for the `emailclassifier` endpoint you created. This value will need to be set when you are deploying the classifier lambda later on
    in the blueprint.

5. **Test the classifier.**  Once the classifier has become `IN_SERVICE` you can test it by issuing the following command. 

    `aws comprehend classify-document --text "Hey I had some questions about what I can use my 529 for in regards to my childrens college tuition.  Can I spend the money on things other then tuition" --endpoint-arn <<YOUR EndpointArn>>`

# Post-Deployment
At this point the setup of the AWS Comprehend classifier is complete. Take note of the `EndpointArn` as the value will be used in the next part of the blueprint setup, the deployment of the API Gateway and AWS Lambda that will be used to call the classifier is located [here](../aws-classifier-lambda).
