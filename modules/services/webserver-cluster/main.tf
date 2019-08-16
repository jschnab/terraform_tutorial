locals {
	http_port = 80
	any_port = 0
	any_protocol = "-1"
	tcp_protocol = "tcp"
	all_ips = ["0.0.0.0/0"]
}

resource "aws_launch_configuration" "launch_config" {
	image_id = "ami-40d28157"
	instance_type = var.instance_type
	security_groups = [aws_security_group.sg_instances.id]
	user_data = data.template_file.user_data.rendered

	lifecycle {
		create_before_destroy = true
	}
}

data "template_file" "user_data" {
	template = file("${path.module}/user_data.sh")

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

	min_size = var.min_size
	max_size = var.max_size

	tag {
		key = "Name"
		value = "${var.cluster_name}-asg"
		propagate_at_launch = true
	}

	dynamic "tag" {
		for_each = var.custom_tags

		content {
			key = tag.key
			value = tag.value
			propagate_at_launch = true
		}
	}
}

resource "aws_autoscaling_schedule" "scale_out_business_hours" {
	count = var.enable_autoscaling ? 1 : 0

	scheduled_action_name = "${var.cluster_name}-scale-out-during-business-hours"
	min_size = 2
	max_size = 10
	desired_capacity = 10
	recurrence = "0 9 * * *"
	autoscaling_group_name = aws_autoscaling_group.asg_test.name
}

resource "aws_autoscaling_schedule" "scale_in_at_night" {
	count = var.enable_autoscaling ? 1 : 0

	scheduled_action_name = "${var.cluster_name}-scale-in-at-night"
	min_size = 2
	max_size = 10
	desired_capacity = 2
	recurrence = "0 17 * * *"
	autoscaling_group_name = aws_autoscaling_group.asg_test.name
}

resource "aws_security_group" "sg_instances" {
	name = "${var.cluster_name}-instances"

	ingress {
		from_port = var.server_port
		to_port = var.server_port
		protocol = local.tcp_protocol
		security_groups = [aws_security_group.sg_alb.id]
	}
}

resource "aws_lb" "app_lb" {
	name = "${var.cluster_name}-alb"
	load_balancer_type = "application"
	subnets = data.aws_subnet_ids.default.ids
	security_groups = [aws_security_group.sg_alb.id]
}

resource "aws_lb_listener" "http" {
	load_balancer_arn = aws_lb.app_lb.arn
	port = local.http_port
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
	name = "${var.cluster_name}-alb"

	ingress {
		from_port = local.http_port
		to_port = local.http_port
		protocol = local.tcp_protocol
		cidr_blocks = local.all_ips
	}

	egress {
		from_port = local.any_port
		to_port = local.any_port
		protocol = local.any_protocol
		cidr_blocks = local.all_ips
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
		bucket = var.db_remote_state_bucket
		key = var.db_remote_state_key
		region = "us-east-1"
	}
}

resource "aws_cloudwatch_metric_alarm" "high_cpu_utilization" {
	alarm_name = "${var.cluster_name}-high-cpu-utilization"
	namespace = "AWS/EC2"
	metric_name = "CPUUtilization"

	dimensions = {AutoScalingGroupName = aws_autoscaling_group.asg_test.name}

	comparison_operator = "GreaterThanThreshold"
	evaluation_periods = 1
	period = 300
	statistic = "Average"
	threshold = 90
	unit = "Percent"
}

resource "aws_cloudwatch_metric_alarm" "low_cpu_credit_balance" {
	count = format("%.1s", var.instance_type) == "t" ? 1 : 0

	alarm_name = "${var.cluster_name}-low-cpu-credit-balance"
	namespace = "AWS/EC2"
	metric_name = "CPUCreditBalance"

	dimensions = {AutoScalingGroupName = aws_autoscaling_group.asg_test.name}

	comparison_operator = "LessThanThreshold"
	evaluation_periods = 1
	period = 300
	statistic = "Minimum"
	threshold = 10
	unit = "Count"
}
