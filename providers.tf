terraform {
  required_providers {
    aws = {
        source = "hashicorp/aws"
        version = "6.74.0"
    }
  }
}

provider "aws" {
  region = var.aws_primary_region
  alias = "primary_region_provider"
}

provider "aws" {
  region = var.aws_secondary_region
  alias = "secondary_region_provider"
}