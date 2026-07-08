variable "cluster_name" {
  description = "Name of the EKS cluster these addons install into."
  type        = string
}

variable "region" {
  description = "AWS region."
  type        = string
}

variable "tags" {
  description = "Tags applied to created AWS resources."
  type        = map(string)
  default     = {}
}

# ------------------------------------------------------------------ secrets
variable "secrets_manager_arns" {
  description = "Secrets Manager ARNs (prefixes) that External Secrets may read."
  type        = list(string)
}

# ------------------------------------------------------------------ gitops
variable "gitops_repo_url" {
  description = "Git URL of this repo; Argo CD's app-of-apps reconciles from it."
  type        = string
}

variable "app_of_apps_path" {
  description = "Path in the repo to the environment's bootstrap overlay."
  type        = string
  default     = "bootstrap/overlays/dev"
}

variable "gitops_repo_ssh_key" {
  description = "SSH deploy key for a PRIVATE gitops repo. Leave empty for a public HTTPS repo."
  type        = string
  default     = ""
  sensitive   = true
}

variable "target_revision" {
  description = "Git revision Argo CD tracks for the app-of-apps."
  type        = string
  default     = "main"
}

# ------------------------------------------------------------------ optional: ALB
variable "enable_alb" {
  description = "Install the AWS Load Balancer Controller (for public Ingress via ALB)."
  type        = bool
  default     = false
}

variable "vpc_id" {
  description = "VPC ID (required when enable_alb = true)."
  type        = string
  default     = ""
}

# ------------------------------------------------------------------ optional: external-dns
variable "enable_external_dns" {
  description = "Install External DNS to manage Route53 records from Ingress/Service objects."
  type        = bool
  default     = false
}

variable "external_dns_domain_filter" {
  description = "Domain External DNS is allowed to manage (e.g. example.com)."
  type        = string
  default     = ""
}

variable "external_dns_zone_arns" {
  description = "Route53 hosted zone ARNs External DNS may write to."
  type        = list(string)
  default     = ["arn:aws:route53:::hostedzone/*"]
}

# ------------------------------------------------------------------ chart versions
variable "chart_versions" {
  description = "Helm chart versions, pinned for reproducibility. Bump deliberately."
  type = object({
    external_secrets = string
    cert_manager     = string
    argo_cd          = string
    alb_controller   = string
    external_dns     = string
  })
  default = {
    external_secrets = "0.10.7"
    cert_manager     = "v1.16.2"
    argo_cd          = "7.7.11"
    alb_controller   = "1.9.2"
    external_dns     = "1.15.0"
  }
}
