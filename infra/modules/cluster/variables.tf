variable "name" {
  description = "Environment name; used as a prefix (e.g. dev -> dev-cluster, dev-vpc)."
  type        = string
}

variable "region" {
  description = "AWS region."
  type        = string
}

# ------------------------------------------------------------------ network
variable "vpc_cidr" {
  description = "CIDR for the environment VPC."
  type        = string
  default     = "10.0.0.0/16"
}

variable "azs" {
  description = "Availability zones for the VPC/cluster."
  type        = list(string)
}

variable "single_nat_gateway" {
  description = "Single NAT gateway (cheaper) vs one per AZ (HA)."
  type        = bool
  default     = true
}

# ------------------------------------------------------------------ cluster
variable "cluster_version" {
  description = "Kubernetes version."
  type        = string
  default     = "1.31"
}

variable "cluster_endpoint_public_access" {
  description = "Expose the Kubernetes API publicly."
  type        = bool
  default     = true
}

variable "node_instance_types" {
  description = "Managed node group instance types."
  type        = list(string)
  default     = ["t3.medium"]
}

variable "node_min_size" {
  description = "Minimum nodes."
  type        = number
  default     = 2
}

variable "node_max_size" {
  description = "Maximum nodes."
  type        = number
  default     = 4
}

variable "node_desired_size" {
  description = "Desired nodes."
  type        = number
  default     = 2
}

# ------------------------------------------------------------------ addons
variable "secrets_manager_arns" {
  description = "Secrets Manager ARN prefixes External Secrets may read."
  type        = list(string)
}

variable "gitops_repo_url" {
  description = "This repo's Git URL for Argo CD."
  type        = string
}

variable "app_of_apps_path" {
  description = "Path to this environment's bootstrap overlay."
  type        = string
}

variable "gitops_repo_ssh_key" {
  description = "SSH deploy key if the gitops repo is private (else empty)."
  type        = string
  default     = ""
  sensitive   = true
}

variable "target_revision" {
  description = "Git revision Argo CD tracks."
  type        = string
  default     = "main"
}

variable "enable_alb" {
  description = "Install the AWS Load Balancer Controller."
  type        = bool
  default     = false
}

variable "enable_external_dns" {
  description = "Install External DNS."
  type        = bool
  default     = false
}

variable "external_dns_domain_filter" {
  description = "Domain External DNS manages."
  type        = string
  default     = ""
}

# ------------------------------------------------------------------ database
variable "enable_rds" {
  description = "Create an RDS PostgreSQL instance (staging/prod). Dev uses in-cluster Postgres."
  type        = bool
  default     = false
}

variable "rds_instance_class" {
  description = "RDS instance class."
  type        = string
  default     = "db.t4g.micro"
}

variable "rds_multi_az" {
  description = "Run RDS across multiple AZs."
  type        = bool
  default     = false
}

variable "rds_deletion_protection" {
  description = "Protect the RDS instance from deletion."
  type        = bool
  default     = true
}

variable "tags" {
  description = "Extra tags merged onto all resources."
  type        = map(string)
  default     = {}
}
