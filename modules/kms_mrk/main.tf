resource "aws_kms_key" "primary" {
  description             = var.description
  deletion_window_in_days = 30
  enable_key_rotation     = true
  multi_region            = true

  # For POC you can let AWS generate the default key policy.
  # Later, replace this with a locked-down policy.
}

resource "aws_kms_alias" "primary_alias" {
  name          = var.alias_name
  target_key_id = aws_kms_key.primary.key_id
}

resource "aws_kms_replica_key" "west2" {
  provider        = aws.west2
  description     = "${var.description} (replica us-west-2)"
  primary_key_arn = aws_kms_key.primary.arn
}

resource "aws_kms_alias" "west2_alias" {
  provider      = aws.west2
  name          = var.alias_name
  target_key_id = aws_kms_replica_key.west2.key_id
}
