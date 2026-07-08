output "repository_urls" {
  description = "Map of repository name to its ECR URL."
  value       = { for name, repo in aws_ecr_repository.this : name => repo.repository_url }
}
