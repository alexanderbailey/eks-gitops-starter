variable "domain_name" {
  description = "The domain / hosted zone name (e.g. example.com)."
  type        = string
}

variable "create_zone" {
  description = "Create the hosted zone. Set false to look up an existing one."
  type        = bool
  default     = true
}

variable "records" {
  description = <<-EOT
    DNS records to manage in the zone. Each entry:
      name    = subdomain relative to the zone, or "" for the apex
      type    = record type (A, CNAME, TXT, MX, ...)
      ttl     = TTL in seconds
      records = list of record values
  EOT
  type = list(object({
    name    = string
    type    = string
    ttl     = optional(number, 300)
    records = list(string)
  }))
  default = []
}

variable "tags" {
  description = "Tags applied to the hosted zone."
  type        = map(string)
  default     = {}
}
