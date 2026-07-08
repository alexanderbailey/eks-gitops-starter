output "cluster_name" {
  description = "EKS cluster name."
  value       = module.eks.cluster_name
}

output "cluster_endpoint" {
  description = "Endpoint for the Kubernetes API server."
  value       = module.eks.cluster_endpoint
}

output "cluster_certificate_authority_data" {
  description = "Base64-encoded CA certificate for the cluster."
  value       = module.eks.cluster_certificate_authority_data
}

output "cluster_version" {
  description = "Kubernetes version of the cluster."
  value       = module.eks.cluster_version
}

output "oidc_provider_arn" {
  description = "OIDC provider ARN (retained for tooling that still expects it; Pod Identity is preferred)."
  value       = module.eks.oidc_provider_arn
}

output "node_security_group_id" {
  description = "Security group attached to the managed nodes (source for RDS access rules)."
  value       = module.eks.node_security_group_id
}
