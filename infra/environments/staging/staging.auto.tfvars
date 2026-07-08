# Staging environment.
# Mirrors production closely: public ALB ingress, External DNS, and RDS —
# but smaller, single-AZ, and without deletion protection.

name             = "staging"
app_of_apps_path = "bootstrap/overlays/staging"

azs      = ["eu-west-2a", "eu-west-2b"]
vpc_cidr = "10.20.0.0/16"

cluster_endpoint_public_access = true
node_instance_types            = ["t3.large"]
node_min_size                  = 2
node_max_size                  = 4
node_desired_size              = 2

enable_alb          = true
enable_external_dns = true

enable_rds              = true
rds_instance_class      = "db.t4g.small"
rds_multi_az            = false
rds_deletion_protection = false
