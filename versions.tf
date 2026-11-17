terraform {
  required_version = "~> 1.15"

  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 6.0"
    }
  }

  # Optional: store state remotely, the same way as my static website project.
  # Create the bucket and DynamoDB table first, then uncomment and run `terraform init`.
  # backend "s3" {
  #   bucket         = "<your-state-bucket>"
  #   key            = "aws-vpc-lab/terraform.tfstate"
  #   region         = "eu-west-2"
  #   dynamodb_table = "<your-lock-table>"
  #   encrypt        = true
  # }
}

provider "aws" {
  region = var.region

  default_tags {
    tags = {
      Project   = "aws-vpc-lab"
      ManagedBy = "Terraform"
      Owner     = "Bushra Alia"
    }
  }
}
