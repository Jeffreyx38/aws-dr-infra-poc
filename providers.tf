terraform {
  backend "s3" {
    bucket         = "jzbx-aws-dr-infra-tf"
    key            = "dr-poc/terraform.tfstate"
    region         = "us-east-1"
    dynamodb_table = "jzbx-aws-dr-infra-tf-locks"
    encrypt        = true
  }

  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }
  }
}

provider "aws" {
  region = "us-east-1"

  default_tags {
    tags = local.default_tags
  }
}

provider "aws" {
  alias  = "west2"
  region = "us-west-2"


  default_tags {
    tags = local.default_tags
  }
}

