terraform {
  required_version = ">= 1.6"
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }
  }
}

provider "aws" {
  region = var.aws_region
}

# Task 3 — AWS billing metrics (EstimatedCharges) are only published in us-east-1,
# so we declare a second provider with an alias that targets that region.
provider "aws" {
  alias  = "us_east_1"
  region = "us-east-1"
}
