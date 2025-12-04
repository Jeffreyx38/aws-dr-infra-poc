output "east_api_domain_name" {
  value = module.app_east.api_target_domain_name
}

output "east_api_hosted_zone_id" {
  value = module.app_east.api_target_hosted_zone_id
}

output "west_api_domain_name" {
  value = module.app_west.api_target_domain_name
}

output "west_api_hosted_zone_id" {
  value = module.app_west.api_target_hosted_zone_id
}
