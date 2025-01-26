# Setting AWS variables
To assume the bob role and use the access point.  You should have two options.  This:
```chatinput
eval $(aws sts assume-role --role-arn arn:aws:iam::{your account}:role/usr1-role --role-session-name usr1-session --profile admin1 --query 'Credentials.[AccessKeyId,SecretAccessKey,SessionToken]' --output text | awk '{print "export AWS_ACCESS_KEY_ID="$1"\nexport AWS_SECRET_ACCESS_KEY="$2"\nexport AWS_SESSION_TOKEN="$3"}')
aws s3 cp main.tf s3://<BOB_ACCESS_POINT>/bobs_files/main.tf
```
unfortunately the below is not working for me, but it should.  Need more research.

```
cat ~/.aws/credentials 
....
[bob]
role_arn = arn:aws:iam::<account id>:role/bob
source_profile = admin1
....
`````
and running this command
```
% aws s3 cp main.tf s3://${BOB_ACCESS_POINT}/bobs_files/main.tf --profile bob
```


# tf_s3_access_point
Deploys an S3 Access Point use-case example via Terraform, where two IAM users have their own S3 Access Point endpoints on a single bucket with access is being restricted by prefix/folder. All S3 permissions are delegated to the S3 Access Point Policies. 

## Prereqs

This was developed and tested with Terraform `v1.3.6`, AWScli `v2.9.9`. It is strongly recommended to deploy this is a sandbox or non-production account. 

# Usage

Set the desired AWS region in the `variables.tf` file.

## Deploying with Terraform
```
terraform init  ## initialize Terraform
terraform plan  ## Review what Terraform will do
terraform apply ## Deploy the resources
```
Tear-down the resources in the stack
```
terraform destroy
```

## Testing S3 Access Point Access & Permissions

Users can not see objects or perform S3 actions against the bucket directly, since the bucket policy is delegating permissions to the Access Point policies.

```
 % ./test.sh 
Enter AWS Account ID: <your accout id> <enter>
...... 
lots of output

```
use AWS configure to set jane profile credentials.

```
aws s3 --profile jane  ls s3-access-point-test202301091743514197000XXXXX
An error occurred (AccessDenied) when calling the ListObjectsV2 operation: Access Denied
```

User `Bob` can LIST, GET and PUT files via his own S3 Access Point alias(endpoint), but does not have access to Jane's files within her prefix/folder.

```
See test.sh output.
``` 

User `Bob` doesn't have access to Jane's S3 Access point or Jane's S3 prefix/folder

```
See test.sh output.
```

