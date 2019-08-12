output "alb_dns_name" {
	value = aws_lb.app_lb.name
	description = "domain name of the load balancer"
}
