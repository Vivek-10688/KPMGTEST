# Define Terraform Provider Setting's From TerraForm WebSite

// For AWS
// URL : https://registry.terraform.io/providers/hashicorp/aws/latest
terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 3.46.0"
    }
  }
  required_version = ">= 1.0.0"
}

# Setup AWS Provider
provider "aws" {
  region = "us-east-1"
}