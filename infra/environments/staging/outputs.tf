output "cluster_name" {
  description = "EKS cluster name. Configure kubectl with: aws eks update-kubeconfig --name <this>"
  value       = module.cluster.cluster_name
}

output "cluster_endpoint" {
  value = module.cluster.cluster_endpoint
}

output "vpc_id" {
  value = module.cluster.vpc_id
}
