output "alb_dns_name" {
	value = aws_lb.app_lb.dns_name
	description = "domain name of the load balancer"
}

output "asg_name" {
	value = aws_autoscaling_group.asg_test.name
	description = "name of the autoscaling group"
}

output "alb_security_group_id" {
	value = aws_security_group.sg_alb.id
	description = "ID of the security group attached to the application load balancer"
}
