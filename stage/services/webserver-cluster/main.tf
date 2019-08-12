terraform {
	required_version = ">= 0.12, < 0.13"

	backend "s3" {
		key = "stage/services/webserver-cluster/terraform.tfstate"
	}
}

provider "aws" {
	region = "us-east-1"
}

resource "aws_launch_configuration" "launch_config" {
	image_id = "ami-40d28157"
	instance_type = "t2.micro"
	security_groups = [aws_security_group.sg_instances.id]
	user_data = data.template_file.user_data.rendered

	lifecycle {
		create_before_destroy = true
	}
}

data "template_file" "user_data" {
	template = file("user_data.sh")

	vars = {
		server_port = var.server_port
		db_address = data.terraform_remote_state.database.outputs.address
		db_port = data.terraform_remote_state.database.outputs.port
	}
}

resource "aws_autoscaling_group" "asg_test" {
	launch_configuration = aws_launch_configuration.launch_config.name
	vpc_zone_identifier = data.aws_subnet_ids.default.ids

	target_group_arns = [aws_lb_target_group.asg.arn]
	health_check_type = "ELB"

	min_size = 2
	max_size = 10

	tag {
		key = "Name"
		value = "terraform-asg-test"
		propagate_at_launch = true
	}
}

resource "aws_security_group" "sg_instances" {
	name = "instances"

	ingress {
		from_port = var.server_port
		to_port = var.server_port
		protocol = "tcp"
		security_groups = [aws_security_group.sg_alb.id]
	}
}

resource "aws_lb" "app_lb" {
	name = var.alb_name
	load_balancer_type = "application"
	subnets = data.aws_subnet_ids.default.ids
	security_groups = [aws_security_group.sg_alb.id]
}

resource "aws_lb_listener" "http" {
	load_balancer_arn = aws_lb.app_lb.arn
	port = 80
	protocol = "HTTP"

	default_action {
		type = "fixed-response"

		fixed_response {
			content_type = "text/plain"
			message_body = "404: page not found"
			status_code = 404
		}
	}
}

resource "aws_lb_target_group" "asg" {
	name = var.alb_name
	port = var.server_port
	protocol = "HTTP"
	vpc_id = data.aws_vpc.default.id

	health_check {
		path = "/"
		protocol = "HTTP"
		matcher = "200"
		interval = 15
		timeout = 6
		healthy_threshold = 2
		unhealthy_threshold = 2
	}
}

resource "aws_lb_listener_rule" "asg" {
	listener_arn = aws_lb_listener.http.arn
	priority = 100

	condition {
		field = "path-pattern"
		values = ["*"]
	}
	
	action {
		type = "forward"
		target_group_arn = aws_lb_target_group.asg.arn
	}
}

resource "aws_security_group" "sg_alb" {
	name = var.alb_security_group_name

	ingress {
		from_port = 80
		to_port = 80
		protocol = "tcp"
		cidr_blocks = ["0.0.0.0/0"]
	}

	egress {
		from_port = 0
		to_port = 0
		protocol = "-1"
		cidr_blocks = ["0.0.0.0/0"]
	}
}

data "aws_vpc" "default" {
	default = true
}

data "aws_subnet_ids" "default" {
	vpc_id = data.aws_vpc.default.id
}

data "terraform_remote_state" "database" {
	backend = "s3"
	
	config = {
		bucket = "terraform-state-jschnab11435"
		key = "stage/data-stores/postgres/terraform.tfstate"
		region = "us-east-1"
	}
}

