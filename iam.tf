
# Create some test IAM users and access keys
# Create IAM role for Bob
resource "aws_iam_role" "bob_role" {
  name = "bob_role"
  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Principal = {
          AWS = "arn:aws:iam::${data.aws_caller_identity.current.account_id}:user/admin1"
        }
        Action = "sts:AssumeRole"
      }
    ]
  })
  provisioner "local-exec" {
    command = "sleep 10"
  }
}

# Attach policies to the role
resource "aws_iam_role_policy" "bob_role_policy" {
  role = aws_iam_role.bob_role.id
  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Action = ["s3:*"]
        Resource = [
          "${aws_s3_access_point.ap1.arn}/*",
          "${aws_s3_access_point.ap1.arn}"
        ]
      }
    ]
  })
}


/*
   Local provisioners - This is because when we create a user and immediately add it into the AP policy
   it can fail. IAM resources are all handled via us-east-1 and have to get replicated/cached etc
   see https://docs.aws.amazon.com/IAM/latest/UserGuide/troubleshoot_general.html#troubleshoot_general_eventual-consistency
   I thought that waiting for the user to exist would fix this, but it doesn't
   command = "aws iam wait user-exists --user-name ${aws_iam_user.my_user.name}"
  
   I also tried using an explicit AWS provider for us-east-1, but that didn't seem to have any effect.
   Sleeping seems to work, but I'm sure if IAM is delayed then it could break. Rerunning the plan solves this,
   but I wanted to find something that makes this a non-problem most of the time.
*/


resource "aws_iam_user" "jane" {
  name = "jane"
  provisioner "local-exec" {
    command = "sleep 10"
  }
}

resource "aws_iam_access_key" "jane" {
  user = aws_iam_user.jane.name
}

output "janes_key_id" {
  value = aws_iam_access_key.jane.id
}

output "janes_secret_key" {
  value     = aws_iam_access_key.jane.secret
  sensitive = true
}
