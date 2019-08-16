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
	source = "../../../../modules/services/webserver-cluster"

	cluster_name = "webserver-stage"
	db_remote_state_bucket = "terraform-state-jschnab11435"
	db_remote_state_key = "stage/data-stores/postgres/terraform.tfstate"
	
	instance_type = "t2.micro"
	min_size = 2
	max_size = 2
	enable_autoscaling = false

	custom_tags = {
		Owner = "jon-schnaps"
		DeployedBy = "terraform"
	}
}

resource "aws_security_group_rule" "allow_testing_inbound" {
	type = "ingress"
	security_group_id = module.webserver_cluster.alb_security_group_id

	from_port = 12345
	to_port = 12345
	protocol = "tcp"
	cidr_blocks = ["0.0.0.0/0"]
}
