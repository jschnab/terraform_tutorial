terraform {
	required_version = ">= 0.12, < 0.13"
	
	backend "s3" {
		key = "s3/terraform.tfstate"
	}
}

provider "aws" {
	region = "us-east-1"
}

resource "aws_s3_bucket" "terraform_state" {
	bucket = "terraform-state-jschnab11435"

	versioning {
		enabled = true
	}

	lifecycle {
		prevent_destroy = true
	}

	server_side_encryption_configuration {
		rule {
			apply_server_side_encryption_by_default {
				sse_algorithm = "AES256"
			}
		}
	}
}
