variable "cluster_name" {
	description = "name to use for all cluster resources"
}

variable "db_remote_state_bucket" {
	description = "name of the S3 bucket used for the database's remote state storage"
	type = string
}

variable "db_remote_state_key" {
	description = "name of the key in the S3 bucket used for the db's remote state storage"
	type = string
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

variable "instance_type" {
	description = "type of the instance to run (e.g. t2.micro)"
	type = string
}

variable "min_size" {
	description = "minimum number of EC2 instances in the ASG"
	type = number
}

variable "max_size" {
	description = "maximum number of EC2 instances in the ASG"
	type = number
}

variable "custom_tags" {
	description = "custom tags to set on the instances of the autoscaling group"
	type = map(string)
	default = {}
}

variable "enable_autoscaling" {
	description = "if set to true, enable autoscaling"
	type  = bool
}
