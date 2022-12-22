
# create bucket
resource "aws_s3_bucket" "s3_ap" {
  bucket_prefix = "s3-access-point-test"
  force_destroy = true
}

#upload upload object to bucket
resource "aws_s3_object" "test_object" {
  bucket = aws_s3_bucket.s3_ap.id
  key    = "images/penguin.png"
  source = "./penguin.png"
}

#create S3 access point for bucket
resource "aws_s3_access_point" "ap1" {
  bucket = aws_s3_bucket.s3_ap.id
  name   = "my-s3ap"
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
      test = "StringEquals"
      variable = "s3:DataAccessPointAccount"
      values = [
        "${data.aws_caller_identity.current.account_id}"
      ]
    }  	
  }
}

# bucket policy 
resource "aws_s3_bucket_policy" "delegate_access_control_to_ap" {
  bucket = aws_s3_bucket.s3_ap.id
  policy = data.aws_iam_policy_document.delegate_access_control_to_ap.json
}

 
data "aws_iam_policy_document" "ap-policy" {
  version = "2012-10-17"
  statement {
    effect = "Allow"
    actions = ["s3:GetObject", "s3:PutObject"]
    principals {
      identifiers = [data.aws_caller_identity.current.arn]
      type = "AWS"
    }
    /*
   ARNs for objects accessed through an access point use the format
   arn:aws:s3:region:account-id:accesspoint/access-point-name/object/resource
    */
    resources = ["${aws_s3_access_point.ap1.arn}/object/images/*"]
  }
  statement {
    effect = "Allow"
    actions = ["s3:List*"]
    principals {
      identifiers = [data.aws_caller_identity.current.arn]
      type = "AWS"
    }
    resources = ["${aws_s3_access_point.ap1.arn}"]
    condition {
      test = "StringLike"
      variable = "s3:prefix"
      values = ["images/*"]
    }
  }
}

# Access Point Policy
resource "aws_s3control_access_point_policy" "bucket-ap-policy" {
  access_point_arn = aws_s3_access_point.ap1.arn
  policy = data.aws_iam_policy_document.ap-policy.json
}

# Outputs
output "s3_access_point_domain" { 
  description = "Domain name of S3 AP"
  value = aws_s3_access_point.ap1.domain_name
}

output "s3_access_alias" {
  description = "Alias of S3 AP"
  value = aws_s3_access_point.ap1.alias
}

