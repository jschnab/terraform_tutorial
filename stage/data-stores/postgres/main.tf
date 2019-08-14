terraform {
	required_version = ">= 0.12, < 0.13"

	backend "s3" {
		key = "stage/data-stores/postgres/terraform.tfstate"
	}
}

provider "aws" {
	region = "us-east-1"
}

resource "aws_db_instance" "postgres_db" {
	identifier_prefix = "terraform-tutorial"
	engine = "postgres"
	allocated_storage = 5
	instance_class = "db.t2.micro"
	name = "postgres_database"
	username = "jschnab"
	password = "${var.db_password}"
	skip_final_snapshot = true
}
