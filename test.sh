#!/bin/bash

# Get the access points for the bucket
get_access_points() {
  BOB_ACCESS_POINT=$(aws s3control list-access-points --account-id ${AWS_ACCOUNT_ID} --query "AccessPointList[?Name=='bobs-s3ap'].Alias" --output text)
  echo "Bob Access Point: $BOB_ACCESS_POINT"
  JANE_ACCESS_POINT=$(aws s3control list-access-points --account-id ${AWS_ACCOUNT_ID} --query "AccessPointList[?Name=='janes-s3ap'].Alias" --output text)
  echo "JANE_ACCESS_POINT Access Point: $JANE_ACCESS_POINT"

}

# Assume the bob_role using admin1 credentials
assume_bob_role() {
  ROLE_ARN="arn:aws:iam::${AWS_ACCOUNT_ID}:role/bob_role"
  SESSION_NAME="admin1-session"

  CREDS=$(aws sts assume-role --role-arn "$ROLE_ARN" --role-session-name "$SESSION_NAME")

  export AWS_ACCESS_KEY_ID=$(echo $CREDS | jq -r '.Credentials.AccessKeyId')
  export AWS_SECRET_ACCESS_KEY=$(echo $CREDS | jq -r '.Credentials.SecretAccessKey')
  export AWS_SESSION_TOKEN=$(echo $CREDS | jq -r '.Credentials.SessionToken')
}

# Upload the main.tf file to the bobs_s3ap access point
bob_process() {

  echo " bob upload main.tf to bob_files"
  aws s3 cp main.tf s3://${BOB_ACCESS_POINT}/bobs_files/main.tf
  echo "**************"
  echo " bob upload main.tf to Jane_files"
  aws s3 cp main.tf s3://${JANE_ACCESS_POINT}/janes_files/bad_main.tf
  echo "**************"
  echo  "ls BOB_ACCESS_POINT"
  aws s3 ls s3://${BOB_ACCESS_POINT}
  echo  "ls BOB_ACCESS_POINT recursively"
  aws s3 ls s3://${BOB_ACCESS_POINT} --recursive
  echo "**************"
  echo "ls BOB_ACCESS_POINT/bobs_files"
  aws s3 ls s3://${BOB_ACCESS_POINT}/bobs_files
  echo "ls BOB_ACCESS_POINT/bobs_files recursively"
  aws s3 ls s3://${BOB_ACCESS_POINT}/bobs_files --recursive
  echo "**************"
  echo "ls BOB_ACCESS_POINT/bobs_files/bobs_files"
  aws s3 ls s3://${BOB_ACCESS_POINT}/bobs_files/bobsfiles
  echo "ls BOB_ACCESS_POINT/bobs_files/bobs_files recursively"
  aws s3 ls s3://${BOB_ACCESS_POINT}/bobs_files/bobsfiles --recursive
  echo "**************"
  echo "copy s3 main to tmp"
  aws s3 cp s3://${BOB_ACCESS_POINT}/bobs_files/main.tf /tmp/main.tf.bak
  if [ -f /tmp/main.tf.bak ]; then
    echo "got file from bucket"
    rm /tmp/main.tf.bak
  else
    echo "copy failed"
  fi
  echo "**************"
  echo "remove bob file"
  aws s3 rm s3://${BOB_ACCESS_POINT}/bobs_files/main.tf
}

read -p "Enter AWS Account ID: " AWS_ACCOUNT_ID
# Main script execution
get_access_points
assume_bob_role
bob_process

#download_file
#delete_file