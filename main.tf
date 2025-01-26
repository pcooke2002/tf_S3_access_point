
locals {
  name   = "myenv"
  region = var.aws_region
  tags = {
    terraform_managed = "true"
    Environment       = "sandbox"
  }
}

provider "aws" {
  region = "us-east-1"
}

terraform {
  required_version = ">= 1.3.0"
}

# This will fetch our account_id, no need to hard code it
data "aws_caller_identity" "current" {}

