terraform {
	required_version = ">= 0.12, < 0.13"

	backend "s3" {
		key = "stage/services/webserver-cluster/terraform.tfstate"
	}
}

provider "aws" {
	region = "us-east-1"
}

module "webserver_cluster" {
	source = "../../../modules/services/webserver-cluster"

	cluster_name = "webserver-prod"
	db_remote_state_bucket = "terraform-state-jschnab11435"
	db_remote_state_key = "prod/data-stores/postgres/terraform.tfstate"
	
	instance_type = "m4.large"
	min_size = 2
	max_size = 10
	enable_autoscaling = true

	custom_tags = {
		Owner = "jon-schnaps"
		DeployedBy = "terraform"
	}
}
