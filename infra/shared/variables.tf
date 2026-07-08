variable "region" {
  description = "AWS region."
  type        = string
  default     = "eu-west-2"
}

variable "ecr_repositories" {
  description = "ECR repositories to create (typically one per app image)."
  type        = list(string)
  default     = ["backend-podinfo", "frontend-nginx", "db-service"]
}

variable "hosted_zones" {
  description = <<-EOT
    Route53 hosted zones to manage, keyed by an arbitrary label. Each value:
      domain_name = the zone (e.g. example.com)
      create_zone = create it, or look up an existing zone
      records     = optional list of DNS records (see the route53 module)
    Leave empty to manage no DNS.
  EOT
  type = map(object({
    domain_name = string
    create_zone = optional(bool, true)
    records = optional(list(object({
      name    = string
      type    = string
      ttl     = optional(number, 300)
      records = list(string)
    })), [])
  }))
  default = {}
}
