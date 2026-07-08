provider "aws" {
  region = var.region

  default_tags {
    tags = {
      Project   = "eks-gitops-starter"
      ManagedBy = "terraform"
      Scope     = "shared"
    }
  }
}
