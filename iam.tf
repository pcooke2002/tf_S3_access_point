
# Create some test IAM users and access keys
resource "aws_iam_user" "bob" {
  name = "bob"
}

resource "aws_iam_access_key" "bob" {
  user = aws_iam_user.bob.name
}

resource "aws_iam_user" "jane" {
  name = "jane"
}

resource "aws_iam_access_key" "jane" {
  user = aws_iam_user.jane.name
}

# Outputs
output "bobs_key_id" {
  value = aws_iam_access_key.bob.id
}

output "bobs_secret_key" {
  value = aws_iam_access_key.bob.secret
  sensitive = true
}

output "janes_key_id" {
  value = aws_iam_access_key.jane.id
}

output "janes_secret_key" {
  value = aws_iam_access_key.jane.secret
  sensitive = true
}
