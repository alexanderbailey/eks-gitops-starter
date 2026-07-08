# Example values for the shared infrastructure. Edit for your setup.
region = "eu-west-2"

ecr_repositories = [
  "backend-podinfo",
  "frontend-nginx",
  "db-service",
]

# Manage DNS by adding zones here. Left with a single example zone; replace
# "example.com" with your domain, or set to {} to manage no DNS.
hosted_zones = {
  primary = {
    domain_name = "example.com"
    create_zone = true
    records = [
      {
        name    = "www"
        type    = "CNAME"
        records = ["example.com"]
      },
    ]
  }
}
