output "ecr_repository_urls" {
  description = "Map of app name to ECR repository URL."
  value       = module.ecr.repository_urls
}

output "hosted_zone_ids" {
  description = "Map of hosted-zone label to zone ID."
  value       = { for k, m in module.route53 : k => m.zone_id }
}

output "hosted_zone_name_servers" {
  description = "Map of hosted-zone label to its name servers (set at the registrar)."
  value       = { for k, m in module.route53 : k => m.name_servers }
}
