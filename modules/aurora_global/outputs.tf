output "primary_cluster_arn" {
  value = aws_rds_cluster.primary.arn
}

output "dr_cluster_arn" {
  value = aws_rds_cluster.dr.arn
}
