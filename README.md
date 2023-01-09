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


### Post deploy steps
Run ```terraform show -json |jq .values.outputs``` to see the Terraform redacted/sensitive outputs for the IAM users, then create 2 AWSCLI profiles for these users:

```
aws configure --profile bob
aws configure --profile jane
```

## Testing S3 Access Point Access & Permissions

Users can not see objects or perform S3 actions against the bucket directly, since the bucket policy is delegating permissions to the Access Point policies.

```
aws s3 --profile bob  ls s3-access-point-test202301091743514197000XXXXX
An error occurred (AccessDenied) when calling the ListObjectsV2 operation: Access Denied

aws s3 --profile jane  ls s3-access-point-test202301091743514197000XXXXX
An error occurred (AccessDenied) when calling the ListObjectsV2 operation: Access Denied
```

User `Bob` can LIST, GET and PUT files via his own S3 Access Point alias(endpoint), but does not have access to Jane's files within her prefix/folder.

```
aws s3 --profile bob ls s3://bobs-s3ap-jb5555agcnrpnba63en7uu3p1yn7qXXXXX-s3alias/bobs_files/
bobs_file.txt
aws s3 --profile bob cp s3://bobs-s3ap-jb5555agcnrpnba63en7uu3p1yn7qXXXXX-s3alias/bobs_files/bobs_file.txt /tmp/
download: s3://bobs-s3ap-jb5555agcnrpnba63en7uu3p1yn7qXXXXX-s3alias/bobs_files/bobs_file.txt to /tmp/bobs_file.txt

``` 

User `Bob` doesn't have access to Jane's S3 Access point or Jane's S3 prefix/folder

```
aws s3 --profile bob  ls s3://janes-s3ap-x7u8jipkuwuisy9ckysqu3xp6gekqXXXXX-s3alias/janes_files/      
An error occurred (AccessDenied) when calling the ListObjectsV2 operation: Access Denied
aws s3 --profile bob  ls s3://bobs-s3ap-jb5555agcnrpnba63en7uu3p1yn7qXXXXX-s3alias/janes_files/            
An error occurred (AccessDenied) when calling the ListObjectsV2 operation: Access Denied
```

Similarly, `Jane` can LIST, GET and PUT files via her own S3 Access Point alias(endpoint), but does not have access to Bob's files within his prefix/folder.

```
aws s3 --profile jane ls s3://janes-s3ap-x7u8jipkuwuisy9ckysqu3xp6gekqXXXXX-s3alias/janes_files/
janes_file.txt
aws s3 --profile jane cp s3://janes-s3ap-x7u8jipkuwuisy9ckysqu3xp6gekqXXXXX-s3alias/janes_files/janes_file.txt /tmp/
download: s3://janes-s3ap-x7u8jipkuwuisy9ckysqu3xp6gekqXXXXX-s3alias/janes_files/janes_file.txt to /tmp/janes_file.txt
```
