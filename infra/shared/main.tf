# Shared infrastructure: resources that live once and are used by every
# environment (container registries, DNS). Separate state from the clusters.

module "ecr" {
  source       = "./modules/ecr"
  repositories = var.ecr_repositories
}

module "route53" {
  source   = "./modules/route53"
  for_each = var.hosted_zones

  domain_name = each.value.domain_name
  create_zone = each.value.create_zone
  records     = each.value.records
}
