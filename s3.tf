# s3.tf

# create bucket
resource "aws_s3_bucket" "s3_ap" {
  bucket_prefix = "s3-access-point-test"
  force_destroy = true
}

#upload upload objects to bucket under different prefixes
resource "aws_s3_object" "bobs_object" {
  bucket = aws_s3_bucket.s3_ap.id
  key    = "bobs_files/bobs_file.txt"
  source = "./bobs_file.txt"
}

resource "aws_s3_object" "jane_object" {
  bucket = aws_s3_bucket.s3_ap.id
  key    = "janes_files/janes_file.txt"
  source = "./janes_file.txt"
}

#create S3 access point for bucket
resource "aws_s3_access_point" "ap1" {
  bucket = aws_s3_bucket.s3_ap.id
  name   = "bobs-s3ap"

}

resource "aws_s3_access_point" "ap2" {
  bucket = aws_s3_bucket.s3_ap.id
  name   = "janes-s3ap"
}

#delegate access control to Access Policy
data "aws_iam_policy_document" "delegate_access_control_to_ap" {
  statement {
    principals {
      type        = "AWS"
      identifiers = ["*"]
    }

    actions = ["*"]

    resources = [
      aws_s3_bucket.s3_ap.arn,
      "${aws_s3_bucket.s3_ap.arn}/*",
    ]

    condition {
      test     = "StringEquals"
      variable = "s3:DataAccessPointAccount"
      values = [
        "${data.aws_caller_identity.current.account_id}"
      ]
    }
  }
}

# bucket policy ensuring all perms are managed via the AP policy
resource "aws_s3_bucket_policy" "delegate_access_control_to_ap" {
  bucket = aws_s3_bucket.s3_ap.id
  policy = data.aws_iam_policy_document.delegate_access_control_to_ap.json
}


# Update the S3 access point policy for Bob
data "aws_iam_policy_document" "bob-ap-policy" {
  version = "2012-10-17"

  # Allow Bob's role to perform PutObject within "bobs_files/" prefix
  statement {
    effect = "Allow"
    actions = [
      "s3:PutObject",
      "s3:GetObject",
      "s3:List*",
    ]
    principals {
      identifiers = [aws_iam_role.bob_role.arn]
      type        = "AWS"
    }
    resources = [
      "${aws_s3_access_point.ap1.arn}/object/bobs_files/*",
      "${aws_s3_access_point.ap1.arn}/object/bobs_files"
    ]
  }

  # Deny PutObject outside "bobs_files/" prefix
  statement {
    effect = "Deny"
    actions = [
      "s3:PutObject",
      "s3:GetObject"
    ]
    principals {
      identifiers = [aws_iam_role.bob_role.arn]
      type        = "AWS"
    }
    not_resources = ["${aws_s3_access_point.ap1.arn}/object/bobs_files/*"]
  }
}

resource "aws_s3control_access_point_policy" "bob-bucket-ap-policy" {
  access_point_arn = aws_s3_access_point.ap1.arn
  policy           = data.aws_iam_policy_document.bob-ap-policy.json
  depends_on       = [aws_iam_role.bob_role]
}


data "aws_iam_policy_document" "jane-ap-policy" {
  version = "2012-10-17"
  statement {
    effect  = "Allow"
    actions = ["s3:GetObject", "s3:PutObject"]
    principals {
      identifiers = [aws_iam_user.jane.arn]
      type        = "AWS"
    }
    /*
   ARNs for objects accessed through an access point use the format
   arn:aws:s3:region:account-id:accesspoint/access-point-name/object/resource
    */
    resources = ["${aws_s3_access_point.ap2.arn}/object/janes_files/*"]
  }
  statement {
    effect  = "Allow"
    actions = ["s3:List*"]
    principals {
      identifiers = [aws_iam_user.jane.arn]
      type        = "AWS"
    }
    resources = ["${aws_s3_access_point.ap2.arn}"]
    condition {
      test     = "StringLike"
      variable = "s3:prefix"
      values   = ["janes_files/*"]
    }
  }
}

# Access Point Policy for Jane
resource "aws_s3control_access_point_policy" "jane-bucket-ap-policy" {
  access_point_arn = aws_s3_access_point.ap2.arn
  policy           = data.aws_iam_policy_document.jane-ap-policy.json
  depends_on       = [aws_iam_user.jane]
}

# Outputs
output "account_id" {
  value = data.aws_caller_identity.current.account_id
}

output "s3_bucket_domain_name" {
  description = "S3 bucket domain name"
  value       = aws_s3_bucket.s3_ap.bucket_domain_name
}

output "s3_bucket_arn" {
  description = "S3 bucket ARN"
  value       = aws_s3_bucket.s3_ap.arn
}

output "s3_bucket_name" {
  description = "S3 bucket name"
  value       = aws_s3_bucket.s3_ap.bucket
}

# output "bobs_s3_access_point_domain" {
#   description = "Domain name of Bobs S3 AP"
#   value = aws_s3_access_point.ap1.domain_name
# }
#
# output "janes_s3_access_point_domain" {
#   description = "Domain name of Janes S3 AP"
#   value = aws_s3_access_point.ap2.domain_name
# }