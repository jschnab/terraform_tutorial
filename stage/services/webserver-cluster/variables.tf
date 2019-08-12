variable "db_remote_state_bucket" {
	description = "name of the S3 bucket used for the database's remote state storage"
	type = string
	default = "terraform-state-jschnab11435"
}

variable "db_remote_state_key" {
	description = "name of the key in the S3 bucket used for the db's remote state storage"
	type = string
	default = "stage/services/webcluster/terraform.tfstate"
}

variable "server_port" {
	description = "Port for HTTP requests"
	default = 8080
}

variable "alb_name" {
	description = "name of the application load balancer"
	type = string
	default = "terraform-app-lb"
}

variable "instance_security_group_name" {
	description = "name of the security group for EC2 instances"
	type = string
	default = "terraform_instances"
}

variable "alb_security_group_name" {
	description = "name of the security group for the application load balancer"
	type = string
	default = "terraform_app_lb"
}
