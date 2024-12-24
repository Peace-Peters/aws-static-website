terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "5.35.0"
    }
  }
}

provider "aws" {
  region  = var.my_bucket_region
  profile = "peace_peter"
  # Configuration options
}