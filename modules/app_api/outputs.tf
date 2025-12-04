# modules/app_api/outputs.tf
output "api_target_domain_name" {
  value = aws_apigatewayv2_domain_name.api_domain.domain_name_configuration[0].target_domain_name
}

output "api_target_hosted_zone_id" {
  value = aws_apigatewayv2_domain_name.api_domain.domain_name_configuration[0].hosted_zone_id
}
