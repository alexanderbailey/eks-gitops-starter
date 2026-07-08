variable "cluster_name" {
  description = "Name of the EKS cluster."
  type        = string
}

variable "cluster_version" {
  description = "Kubernetes version for the EKS cluster."
  type        = string
  default     = "1.31"
}

variable "vpc_id" {
  description = "VPC to create the cluster in."
  type        = string
}

variable "subnet_ids" {
  description = "Subnet IDs for the cluster and node groups (private subnets)."
  type        = list(string)
}

variable "cluster_endpoint_public_access" {
  description = "Expose the Kubernetes API endpoint publicly. Keep false for private clusters."
  type        = bool
  default     = true
}

variable "node_instance_types" {
  description = "Instance types for the managed node group."
  type        = list(string)
  default     = ["t3.medium"]
}

variable "node_min_size" {
  description = "Minimum node count."
  type        = number
  default     = 2
}

variable "node_max_size" {
  description = "Maximum node count."
  type        = number
  default     = 4
}

variable "node_desired_size" {
  description = "Desired node count."
  type        = number
  default     = 2
}

variable "tags" {
  description = "Tags applied to all resources."
  type        = map(string)
  default     = {}
}
