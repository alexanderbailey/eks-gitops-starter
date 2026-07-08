# A single, fully parametrised hosted zone + records. Unlike a per-domain
# directory tree, everything here is driven by variables, so one module
# instance manages one zone and you scale by adding instances (see the
# `hosted_zones` map in the shared root).

resource "aws_route53_zone" "this" {
  count = var.create_zone ? 1 : 0
  name  = var.domain_name
  tags  = var.tags
}

data "aws_route53_zone" "existing" {
  count = var.create_zone ? 0 : 1
  name  = var.domain_name
}

locals {
  zone_id = var.create_zone ? aws_route53_zone.this[0].zone_id : data.aws_route53_zone.existing[0].zone_id

  # Key records by "name/type" so for_each has a stable, unique key.
  records = { for r in var.records : "${r.name}/${r.type}" => r }
}

resource "aws_route53_record" "this" {
  for_each = local.records

  zone_id = local.zone_id
  name    = each.value.name == "" ? var.domain_name : "${each.value.name}.${var.domain_name}"
  type    = each.value.type
  ttl     = each.value.ttl
  records = each.value.records
}
