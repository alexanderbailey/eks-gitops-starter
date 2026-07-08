output "argocd_namespace" {
  description = "Namespace Argo CD is installed in."
  value       = helm_release.argocd.namespace
}

output "eso_role_arn" {
  description = "IAM role ARN External Secrets assumes via Pod Identity."
  value       = module.eso_pod_identity.iam_role_arn
}
