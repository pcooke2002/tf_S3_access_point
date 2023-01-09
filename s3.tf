
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
      test = "StringEquals"
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

 
data "aws_iam_policy_document" "bob-ap-policy" {
  version = "2012-10-17"
  statement {
    effect = "Allow"
    actions = ["s3:GetObject", "s3:PutObject"]
    principals {
      identifiers = [aws_iam_user.bob.arn]
      type = "AWS"
    }
    /*
   ARNs for objects accessed through an access point use the format
   arn:aws:s3:region:account-id:accesspoint/access-point-name/object/resource
    */
    resources = ["${aws_s3_access_point.ap1.arn}/object/bobs_files/*"]
  }
  statement {
    effect = "Allow"
    actions = ["s3:List*"]
    principals {
      identifiers = [aws_iam_user.bob.arn]
      type = "AWS"
    }
    resources = ["${aws_s3_access_point.ap1.arn}"]
    condition {
      test = "StringLike"
      variable = "s3:prefix"
      values = ["bobs_files/*"]
    }
  }
}

data "aws_iam_policy_document" "jane-ap-policy" {
  version = "2012-10-17"
  statement {
    effect = "Allow"
    actions = ["s3:GetObject", "s3:PutObject"]
    principals {
      identifiers = [aws_iam_user.jane.arn]
      type = "AWS"
    }
    /*
   ARNs for objects accessed through an access point use the format
   arn:aws:s3:region:account-id:accesspoint/access-point-name/object/resource
    */
    resources = ["${aws_s3_access_point.ap2.arn}/object/janes_files/*"]
  }
  statement {
    effect = "Allow"
    actions = ["s3:List*"]
    principals {
      identifiers = [aws_iam_user.jane.arn]
      type = "AWS"
    }
    resources = ["${aws_s3_access_point.ap2.arn}"]
    condition {
      test = "StringLike"
      variable = "s3:prefix"
      values = ["janes_files/*"]
    }
  }
}

# Access Point Policy for Bob
resource "aws_s3control_access_point_policy" "bob-bucket-ap-policy" {
  access_point_arn = aws_s3_access_point.ap1.arn
  policy = data.aws_iam_policy_document.bob-ap-policy.json
  depends_on = [aws_iam_user.bob] 
}

# Access Point Policy for Jane
resource "aws_s3control_access_point_policy" "jane-bucket-ap-policy" {
  access_point_arn = aws_s3_access_point.ap2.arn
  policy = data.aws_iam_policy_document.jane-ap-policy.json
  depends_on = [aws_iam_user.jane] 
}

# Outputs
output "s3_bucket" {
  description = "S3 bucket domain name"
  value = aws_s3_bucket.s3_ap.bucket_domain_name 
}

output "bobs_s3_access_point_domain" { 
  description = "Domain name of Bobs S3 AP"
  value = aws_s3_access_point.ap1.domain_name
}

output "bobs_s3_access_alias" {
  description = "Alias of Bobs S3 AP"
  value = aws_s3_access_point.ap1.alias
}

output "janes_s3_access_point_domain" {
  description = "Domain name of Janes S3 AP"
  value = aws_s3_access_point.ap2.domain_name
}

output "janes_s3_access_alias" {
  description = "Alias of Janes S3 AP"
  value = aws_s3_access_point.ap2.alias
}

