variable "repositories" {
  description = "ECR repository names to create."
  type        = list(string)
}

variable "image_tag_mutability" {
  description = "MUTABLE or IMMUTABLE tags."
  type        = string
  default     = "IMMUTABLE"
}

variable "scan_on_push" {
  description = "Scan images for vulnerabilities on push."
  type        = bool
  default     = true
}

variable "max_image_count" {
  description = "Number of most-recent images to keep; older ones expire."
  type        = number
  default     = 20
}

variable "tags" {
  description = "Tags applied to all repositories."
  type        = map(string)
  default     = {}
}
