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

## route53 app_api module

locals {
  root_domain     = "jzbx.net"
  api_domain_name = "api.jzbx.net"
}

##############################
# Existing Secrets Manager secrets
##############################

# us-east-1 secret: dr-poc/aurora/admin
data "aws_secretsmanager_secret" "aurora_admin_east" {
  name = "dr-poc/aurora/admin"
}

# us-west-2 secret: dr-poc/aurora/admin
data "aws_secretsmanager_secret" "aurora_admin_west" {
  provider = aws.west2
  name     = "dr-poc/aurora/admin"
}


#####################
# Route 53 hosted zone (look up existing)
#####################

# # If jzbx.net is already hosted in Route53
# data "aws_route53_zone" "main" {
#   name         = local.root_domain
#   private_zone = false
# }

#####################
# ACM certificates (one per region)
#####################

# us-east-1 cert for api.jzbx.net
data "aws_acm_certificate" "east_api" {
  domain      = local.api_domain_name # <- was domain_name
  most_recent = true
  statuses    = ["ISSUED"]
}

# us-west-2 cert for api.jzbx.net (create it in that region first)
data "aws_acm_certificate" "west_api" {
  provider    = aws.west2
  domain      = local.api_domain_name # <- was domain_name
  most_recent = true
  statuses    = ["ISSUED"]
}

#####################
# Simple app layer (Lambda + API Gateway) – EAST
#####################

module "app_east" {
  source = "./modules/app_api"

  # region info (optional, mostly for naming)
  region      = "us-east-1"
  lambda_name = "dr-poc-users-east"

  db_cluster_arn = module.aurora_global.primary_cluster_arn
  db_secret_arn  = data.aws_secretsmanager_secret.aurora_admin_east.arn
  kms_key_arn    = module.kms_mrk_shared.primary_key_arn # your MRK in us-east-1

  # custom domain wiring
  domain_name     = local.api_domain_name
  certificate_arn = data.aws_acm_certificate.east_api.arn
  # route53_zone_id = data.aws_route53_zone.main.zone_id
}


#####################
# Simple app layer (Lambda + API Gateway) – WEST
#####################

module "app_west" {
  source = "./modules/app_api"

  providers = {
    aws = aws.west2
  }

  region      = "us-west-2"
  lambda_name = "dr-poc-users-west"

  db_cluster_arn = module.aurora_global.dr_cluster_arn
  db_secret_arn  = data.aws_secretsmanager_secret.aurora_admin_west.arn
  kms_key_arn    = module.kms_mrk_shared.west2_key_arn # MRK replica

  domain_name     = local.api_domain_name
  certificate_arn = data.aws_acm_certificate.west_api.arn
  # route53_zone_id = data.aws_route53_zone.main.zone_id
}
