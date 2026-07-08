# Values under "from setup.sh" are written to zz_generated.auto.tfvars by
# ./setup.sh from your .env. The rest are committed per-environment defaults.

# ---- from setup.sh -------------------------------------------------------
variable "region" {
  type    = string
  default = "eu-west-2"
}

variable "aws_account_id" {
  description = "Used to scope the Secrets Manager IAM policy."
  type        = string
  default     = ""
}

variable "cluster_domain" {
  description = "DNS zone for this environment's services."
  type        = string
  default     = "example.com"
}

variable "gitops_repo_url" {
  type    = string
  default = "https://github.com/your-org/eks-gitops-starter.git"
}

variable "gitops_repo_ssh_key" {
  description = "SSH deploy key if the gitops repo is private."
  type        = string
  default     = ""
  sensitive   = true
}

variable "enable_tailscale" {
  description = "Consumed by the GitOps layer (bootstrap), not by Terraform. Declared here so setup.sh can write one tfvars file."
  type        = bool
  default     = false
}

# ---- environment-specific (committed) ------------------------------------
variable "name" {
  type    = string
  default = "prod"
}

variable "app_of_apps_path" {
  type    = string
  default = "bootstrap/overlays/prod"
}

variable "vpc_cidr" {
  type    = string
  default = "10.0.0.0/16"
}

variable "single_nat_gateway" {
  description = "Single NAT gateway (cheaper) vs one per AZ (HA)."
  type        = bool
  default     = true
}

variable "azs" {
  type    = list(string)
  default = ["eu-west-2a", "eu-west-2b"]
}

variable "cluster_version" {
  type    = string
  default = "1.31"
}

variable "cluster_endpoint_public_access" {
  type    = bool
  default = true
}

variable "node_instance_types" {
  type    = list(string)
  default = ["t3.medium"]
}

variable "node_min_size" {
  type    = number
  default = 1
}

variable "node_max_size" {
  type    = number
  default = 3
}

variable "node_desired_size" {
  type    = number
  default = 2
}

variable "enable_alb" {
  type    = bool
  default = false
}

variable "enable_external_dns" {
  type    = bool
  default = false
}

variable "enable_rds" {
  type    = bool
  default = false
}

variable "rds_instance_class" {
  type    = string
  default = "db.t4g.micro"
}

variable "rds_multi_az" {
  type    = bool
  default = false
}

variable "rds_deletion_protection" {
  type    = bool
  default = true
}
