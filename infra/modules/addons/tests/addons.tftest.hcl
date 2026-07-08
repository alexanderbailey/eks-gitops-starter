# Tests the conditional wiring of optional addons. All providers mocked.
mock_provider "aws" {
  # IAM policy documents must be valid JSON or aws_iam_role validation fails.
  mock_data "aws_iam_policy_document" {
    defaults = {
      json = "{\"Version\":\"2012-10-17\",\"Statement\":[]}"
    }
  }
}
mock_provider "helm" {}
mock_provider "kubernetes" {}
mock_provider "kubectl" {}

variables {
  cluster_name         = "test-cluster"
  region               = "eu-west-2"
  secrets_manager_arns = ["arn:aws:secretsmanager:eu-west-2:123456789012:secret:*"]
  gitops_repo_url      = "https://github.com/example/eks-gitops-starter.git"
}

run "optional_addons_off_by_default" {
  command = plan

  assert {
    condition     = length(helm_release.aws_load_balancer_controller) == 0
    error_message = "ALB controller should not be installed unless enable_alb = true."
  }
  assert {
    condition     = length(helm_release.external_dns) == 0
    error_message = "External DNS should not be installed unless enable_external_dns = true."
  }
  assert {
    condition     = length(kubernetes_secret.gitops_repo) == 0
    error_message = "No repo secret should be created for a public (no ssh key) repo."
  }
}

run "core_addons_always_present" {
  command = plan

  assert {
    condition     = helm_release.external_secrets.name == "external-secrets"
    error_message = "External Secrets is a core addon and must always be installed."
  }
  assert {
    condition     = helm_release.cert_manager.name == "cert-manager"
    error_message = "cert-manager is a core addon and must always be installed."
  }
}

run "enabling_optionals_creates_them" {
  command = plan
  variables {
    enable_alb                 = true
    vpc_id                     = "vpc-0123456789abcdef0"
    enable_external_dns        = true
    external_dns_domain_filter = "example.com"
    gitops_repo_ssh_key        = "dummy-private-key"
  }

  assert {
    condition     = length(helm_release.aws_load_balancer_controller) == 1
    error_message = "enable_alb = true should install the ALB controller."
  }
  assert {
    condition     = length(helm_release.external_dns) == 1
    error_message = "enable_external_dns = true should install External DNS."
  }
  assert {
    condition     = length(kubernetes_secret.gitops_repo) == 1
    error_message = "A private repo ssh key should create the Argo CD repo secret."
  }
}
