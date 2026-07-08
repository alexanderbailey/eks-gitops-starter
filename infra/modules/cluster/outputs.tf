# Exposed so the environment root can configure the k8s-family providers.
output "cluster_name" {
  description = "EKS cluster name."
  value       = module.eks.cluster_name
}

output "cluster_endpoint" {
  description = "Kubernetes API endpoint."
  value       = module.eks.cluster_endpoint
}

output "cluster_certificate_authority_data" {
  description = "Base64 CA data for the cluster."
  value       = module.eks.cluster_certificate_authority_data
}

output "vpc_id" {
  description = "Environment VPC ID."
  value       = module.vpc.vpc_id
}

output "rds_endpoint" {
  description = "RDS endpoint (null when enable_rds = false)."
  value       = var.enable_rds ? module.rds[0].endpoint : null
}

output "rds_master_user_secret_arn" {
  description = "Secrets Manager ARN of the RDS master credentials (null when enable_rds = false)."
  value       = var.enable_rds ? module.rds[0].master_user_secret_arn : null
}
