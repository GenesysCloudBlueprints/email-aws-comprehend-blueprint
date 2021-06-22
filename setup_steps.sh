I.   Environment Setup 
     A.  Configure AWS Secret and Key
          1.  Set AWS_SECRET_ACCESS_KEY
          2.  Set AWS_SECRET_ACCESS_KEY
     B.  Install AWS CLI
     C.  Install GC CLI
     D.  Install Archy     


I.   Setting up the Classifier
     a. Setup the S3 Bucket 
        1.  aws s3api create-bucket --acl private --bucket emailclassifier-poc --region us-east-1  //Make your bucket name unique
        2.  aws s3 cp resources/comprehendterms.csv s3://emailclassifier-poc
     b. Setup the IAM Role and policy
        1.   aws iam create-role --role-name EmailClassifierBucketAccessRole --assume-role-policy-document file://setupscripts/EmailClassifierBucketAccessRole-TrustPolicy.json
        2.   aws iam put-role-policy --role-name EmailClassifierBucketAccessRole --policy-name BucketAccessPolicy --policy-document file://setupscripts/EmailClassifierBucketAccessRole-Permissions.json
        3.  NOTE: The arn returned on the create-role.  You are going to need it for the create-document-classifier
     c. Setup the Document Classifier
        1.  aws comprehend create-document-classifier --document-classifier-name FinancialServices --data-access-role-arn arn:aws:iam::490606849374:role/EmailClassifierBucketAccessRole --input-data-config S3Uri=s3://inindca-public/devengage/comprehendterms.csv --language-code en 
        2.  aws comprehend list-document-classifiers  - List the current classifiers. Also you will ned the DocumentClassifierArn to   
        3. aws comprehend create-endpoint --endpoint-name emailclassifier --model-arn arn:aws:comprehend:us-east-1:490606849374:document-classifier/FinancialServices --desired-inference-units 1 
     d. Setup the Classifier Endpoint (for realtime analysis)
        4. aws comprehend list-endpoints
        5. aws comprehend classify-document --text "Hey I had some questions about what I can use my 529 for in regards to my childrens college tuition.  Can I spend the money on things other then tuition" --endpoint-arn arn:aws:comprehend:us-east-1:490606849374:document-classifier-endpoint/emailclassifier
   
II.  Setting up the Lambda and API Gateway
     1. Modify the classifier ARN for the lambda
     2. Run Serverless

III.  Setting up Genesys

Create:   terraform apply --auto-approve --var-file="/Users/johncarnell/genesys_terraform/carnell1_dev/dev.tfvars" 
Destroy:  terraform destroy --auto-approve --var-file="/Users/johncarnell/genesys_terraform/carnell1_prod/prod.tfvars" 
