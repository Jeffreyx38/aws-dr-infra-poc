data "aws_caller_identity" "current" {}

locals {
  account_id = data.aws_caller_identity.current.account_id
}

locals {
  default_tags = {
    Project  = "dr-poc"
    Owner    = "jzbx"
    Env      = "poc"
    AutoNuke = "true"
  }
}

resource "aws_s3_bucket" "sanity" {
  bucket = "dr-poc-sanity-${local.account_id}"
}

### NETWORK ###


module "network_east" {
  source = "./modules/network_vpc"

  vpc_cidr = "10.10.0.0/16"
}

module "network_west" {
  source = "./modules/network_vpc"

  providers = {
    aws = aws.west2
  }

  vpc_cidr = "10.20.0.0/16"
}

### KMS ###

module "kms_mrk_shared" {
  source = "./modules/kms_mrk"

  providers = {
    aws       = aws
    aws.west2 = aws.west2
  }

  description = "Shared MRK for DR POC"
  alias_name  = "alias/jzbx/poc/shared-mrk"
}


