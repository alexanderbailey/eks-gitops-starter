# Unit tests for the ECR module. Providers are mocked, so no AWS access.
mock_provider "aws" {}

variables {
  repositories = ["app-one", "app-two"]
}

run "one_repo_and_policy_per_name" {
  command = plan

  assert {
    condition     = length(aws_ecr_repository.this) == 2
    error_message = "Expected exactly one ECR repository per name."
  }

  assert {
    condition     = length(aws_ecr_lifecycle_policy.this) == 2
    error_message = "Expected a lifecycle policy attached to every repository."
  }
}

run "repos_default_to_immutable_and_scanned" {
  command = plan

  assert {
    condition     = aws_ecr_repository.this["app-one"].image_tag_mutability == "IMMUTABLE"
    error_message = "Repositories should default to immutable tags."
  }

  assert {
    condition     = aws_ecr_repository.this["app-one"].image_scanning_configuration[0].scan_on_push
    error_message = "Repositories should scan on push by default."
  }
}
