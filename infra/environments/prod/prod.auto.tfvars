# Production environment.
# Public ALB ingress, External DNS, HA RDS with deletion protection, and
# per-AZ NAT gateways. Larger node group with headroom to scale.

name             = "prod"
app_of_apps_path = "bootstrap/overlays/prod"

azs      = ["eu-west-2a", "eu-west-2b", "eu-west-2c"]
vpc_cidr = "10.30.0.0/16"

cluster_endpoint_public_access = true
node_instance_types            = ["t3.large"]
node_min_size                  = 3
node_max_size                  = 10
node_desired_size              = 3

enable_alb          = true
enable_external_dns = true

enable_rds              = true
rds_instance_class      = "db.t4g.medium"
rds_multi_az            = true
rds_deletion_protection = true

# Production uses one NAT gateway per AZ for availability.
single_nat_gateway = false
