# Unit tests for the Route53 module. Providers are mocked, so no AWS access.
mock_provider "aws" {}

variables {
  domain_name = "example.com"
  records = [
    { name = "www", type = "CNAME", records = ["example.com"] },
    { name = "", type = "A", ttl = 60, records = ["203.0.113.10"] },
  ]
}

run "creates_zone_and_records" {
  command = plan

  assert {
    condition     = length(aws_route53_zone.this) == 1
    error_message = "create_zone defaults to true, so the zone should be created."
  }

  assert {
    condition     = length(aws_route53_record.this) == 2
    error_message = "Expected one record resource per input record."
  }
}

run "apex_record_uses_bare_domain" {
  command = plan

  assert {
    condition     = aws_route53_record.this["/A"].name == "example.com"
    error_message = "An empty record name should map to the zone apex (bare domain)."
  }

  assert {
    condition     = aws_route53_record.this["www/CNAME"].name == "www.example.com"
    error_message = "A named record should be prefixed onto the domain."
  }
}

run "existing_zone_is_looked_up_not_created" {
  command = plan
  variables {
    create_zone = false
  }

  assert {
    condition     = length(aws_route53_zone.this) == 0
    error_message = "With create_zone = false, no zone resource should be created."
  }
}
