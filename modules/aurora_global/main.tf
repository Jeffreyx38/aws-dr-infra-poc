##################################
# Global cluster
##################################
resource "aws_rds_global_cluster" "this" {
  global_cluster_identifier = var.global_cluster_identifier
  engine                    = "aurora-mysql"

  # 🔑 Make the global cluster encrypted, same as the DB clusters
  storage_encrypted = true
}

##################################
# Primary cluster (us-east-1)
##################################
resource "aws_rds_cluster" "primary" {
  engine                    = "aurora-mysql"
  engine_version            = "8.0.mysql_aurora.3.08.2" # adjust as needed
  global_cluster_identifier = aws_rds_global_cluster.this.id

  master_username = var.master_username
  master_password = var.master_password

  kms_key_id        = var.kms_key_arn_primary
  storage_encrypted = true

  db_subnet_group_name   = var.db_subnet_group_name_primary
  vpc_security_group_ids = var.vpc_security_group_ids_primary

  enable_http_endpoint = true

  backup_retention_period = 1
  preferred_backup_window = "03:00-04:00"

  # ✅ Serverless v2 bit
  engine_mode = "provisioned"
  serverlessv2_scaling_configuration {
    min_capacity = 0.5 # ACUs – matches what you picked in the console
    max_capacity = 1
  }

  # New for easy destroy in POC
  skip_final_snapshot = true
  deletion_protection = false
}

resource "aws_rds_cluster_instance" "primary_instances" {
  count              = 1
  identifier         = "aurora-primary-${count.index}"
  cluster_identifier = aws_rds_cluster.primary.id
  instance_class     = "db.serverless"
  engine             = aws_rds_cluster.primary.engine
  engine_version     = aws_rds_cluster.primary.engine_version
}

##################################
# DR cluster (us-west-2)
##################################
resource "aws_rds_cluster" "dr" {
  provider                      = aws.west2
  engine                        = "aurora-mysql"
  engine_version                = aws_rds_cluster.primary.engine_version
  global_cluster_identifier     = aws_rds_global_cluster.this.id
  replication_source_identifier = aws_rds_cluster.primary.arn

  kms_key_id        = var.kms_key_arn_dr
  storage_encrypted = true

  db_subnet_group_name   = var.db_subnet_group_name_dr
  vpc_security_group_ids = var.vpc_security_group_ids_dr

  enable_http_endpoint = true

  engine_mode = "provisioned"
  serverlessv2_scaling_configuration {
    min_capacity = 0.5
    max_capacity = 1
  }

  backup_retention_period = 1

  # New for easy destroy in POC
  skip_final_snapshot = true
  deletion_protection = false
}

resource "aws_rds_cluster_instance" "dr_instances" {
  provider           = aws.west2
  count              = 1
  identifier         = "aurora-dr-${count.index}"
  cluster_identifier = aws_rds_cluster.dr.id
  instance_class     = "db.serverless"
  engine             = aws_rds_cluster.dr.engine
  engine_version     = aws_rds_cluster.dr.engine_version
}

##################################
# Outputs
##################################
output "primary_endpoint" {
  value = aws_rds_cluster.primary.endpoint
}

output "primary_reader_endpoint" {
  value = aws_rds_cluster.primary.reader_endpoint
}

output "dr_endpoint" {
  value = aws_rds_cluster.dr.endpoint
}
