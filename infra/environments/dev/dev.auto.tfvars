# Development environment.
# Smallest/cheapest: single NAT, no public load balancer, no External DNS.
# The dev cluster runs ephemeral in-cluster databases instead of RDS.

name             = "dev"
app_of_apps_path = "bootstrap/overlays/dev"

azs      = ["eu-west-2a", "eu-west-2b"]
vpc_cidr = "10.10.0.0/16"

cluster_endpoint_public_access = true
node_instance_types            = ["t3.medium"]
node_min_size                  = 1
node_max_size                  = 3
node_desired_size              = 2

# Dev keeps traffic internal (Tailscale / port-forward), so no ALB or DNS.
enable_alb          = false
enable_external_dns = false
