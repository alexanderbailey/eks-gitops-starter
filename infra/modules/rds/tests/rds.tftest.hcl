# Unit tests for the RDS module. Providers are mocked, so no AWS access.
mock_provider "aws" {}

variables {
  name                       = "test-db"
  vpc_id                     = "vpc-0123456789abcdef0"
  subnet_ids                 = ["subnet-aaa", "subnet-bbb"]
  allowed_security_group_ids = ["sg-111", "sg-222"]
}

run "password_managed_and_access_scoped" {
  command = plan

  assert {
    condition     = aws_db_instance.this.manage_master_user_password == true
    error_message = "Master password must be managed by RDS/Secrets Manager, never set in Terraform."
  }

  assert {
    condition     = length(aws_vpc_security_group_ingress_rule.postgres) == 2
    error_message = "Expected one ingress rule per allowed security group."
  }

  assert {
    condition     = aws_db_instance.this.publicly_accessible == false
    error_message = "The database must not be publicly accessible."
  }
}

run "deletion_protection_on_keeps_final_snapshot" {
  command = plan
  variables {
    deletion_protection = true
  }

  assert {
    condition     = aws_db_instance.this.skip_final_snapshot == false
    error_message = "With deletion protection on, a final snapshot should be taken."
  }
}

run "deletion_protection_off_skips_final_snapshot" {
  command = plan
  variables {
    deletion_protection = false
  }

  assert {
    condition     = aws_db_instance.this.skip_final_snapshot == true
    error_message = "With deletion protection off, the final snapshot should be skipped."
  }
}
