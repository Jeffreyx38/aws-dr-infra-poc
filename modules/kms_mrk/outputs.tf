output "primary_key_arn" {
  value = aws_kms_key.primary.arn
}

output "west2_key_arn" {
  value = aws_kms_replica_key.west2.arn
}

output "alias_name" {
  value = var.alias_name
}
