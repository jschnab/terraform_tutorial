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
}

resource "aws_autoscaling_schedule" "scale_out_business_hours" {
	scheduled_action_name = "scale-out-during-business-hours"
	min_size = 2
	max_size = 10
	desired_capacity = 10
	recurrence = "0 9 * * *"

	autoscaling_group_name = module.webserver_cluster.asg_name
}

resource "aws_autoscaling_schedule" "scale_in_night" {
	scheduled_action_name = "scale-in-at-night"
	min_size = 2
	max_size = 10
	desired_capacity = 2
	recurrence = "0 17 * * *"

	autoscaling_group_name = module.webserver_cluster.asg_name
}
