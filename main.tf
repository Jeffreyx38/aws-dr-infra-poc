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


### AURORA ###


module "aurora_global" {
  source = "./modules/aurora_global"

  providers = {
    aws       = aws
    aws.west2 = aws.west2
  }

  global_cluster_identifier = "dr-poc-aurora-global"

  kms_key_arn_primary = module.kms_mrk_shared.primary_key_arn
  kms_key_arn_dr      = module.kms_mrk_shared.west2_key_arn

  master_username = var.db_master_username
  master_password = var.db_master_password


  db_subnet_group_name_primary = module.network_east.db_subnet_group_name
  db_subnet_group_name_dr      = module.network_west.db_subnet_group_name

  vpc_security_group_ids_primary = [module.network_east.db_security_group_id]
  vpc_security_group_ids_dr      = [module.network_west.db_security_group_id]
}
