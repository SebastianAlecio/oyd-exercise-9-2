# Outputs surfaced from the observability module
output "log_group_name" {
  description = "Name of the CloudWatch log group"
  value       = module.observability.log_group_name
}

output "sns_topic_arn" {
  description = "ARN of the SNS alerts topic (default region)"
  value       = module.observability.sns_topic_arn
}

output "sns_topic_arn_us_east_1" {
  description = "ARN of the SNS alerts topic in us-east-1 (used by the billing alarm)"
  value       = module.observability.sns_topic_arn_us_east_1
}

output "alarm_names" {
  description = "Names of the CloudWatch metric alarms"
  value       = module.observability.alarm_names
}

# Exercise 9.2 — Task 3: surface the dashboard URL from the module
output "dashboard_url" {
  description = "Direct link to the CloudWatch dashboard"
  value       = module.observability.dashboard_url
}

# DNS name of the ALB — target for the traffic-generation step (Task 4)
output "alb_dns_name" {
  description = "Public DNS name of the FinAPI ALB (use it to generate traffic)"
  value       = aws_lb.finapi.dns_name
}
