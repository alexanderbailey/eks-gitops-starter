variable "name" {
  description = "Identifier for the RDS instance and its resources."
  type        = string
}

variable "vpc_id" {
  description = "VPC to place the database in (same VPC as the cluster)."
  type        = string
}

variable "subnet_ids" {
  description = "Private subnet IDs for the DB subnet group."
  type        = list(string)
}

variable "allowed_security_group_ids" {
  description = "Security groups allowed to reach the database (e.g. the EKS node SG)."
  type        = list(string)
}

variable "engine_version" {
  description = "PostgreSQL engine version."
  type        = string
  default     = "16.4"
}

variable "instance_class" {
  description = "RDS instance class."
  type        = string
  default     = "db.t4g.micro"
}

variable "allocated_storage" {
  description = "Initial storage (GB)."
  type        = number
  default     = 20
}

variable "max_allocated_storage" {
  description = "Storage autoscaling ceiling (GB)."
  type        = number
  default     = 100
}

variable "db_name" {
  description = "Name of the initial database."
  type        = string
  default     = "app"
}

variable "username" {
  description = "Master username."
  type        = string
  default     = "app"
}

variable "multi_az" {
  description = "Deploy across multiple AZs (HA)."
  type        = bool
  default     = false
}

variable "deletion_protection" {
  description = "Refuse to delete the instance while true."
  type        = bool
  default     = true
}

variable "port" {
  description = "Database port."
  type        = number
  default     = 5432
}

variable "tags" {
  description = "Tags applied to all resources."
  type        = map(string)
  default     = {}
}
