output "zone_id" {
  description = "Hosted zone ID."
  value       = local.zone_id
}

output "name_servers" {
  description = "Name servers for the zone (set these at your registrar when creating a new zone)."
  value       = var.create_zone ? aws_route53_zone.this[0].name_servers : []
}

output "zone_arn" {
  description = "Hosted zone ARN (useful for scoping External DNS IAM)."
  value       = "arn:aws:route53:::hostedzone/${local.zone_id}"
}
