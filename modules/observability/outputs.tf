output "log_group_name" {
  description = "Name of the CloudWatch log group"
  value       = aws_cloudwatch_log_group.finapi.name
}

output "sns_topic_arn" {
  description = "ARN of the SNS alerts topic (default region)"
  value       = aws_sns_topic.alerts.arn
}

output "sns_topic_arn_us_east_1" {
  description = "ARN of the SNS alerts topic in us-east-1 (used by the billing alarm)"
  value       = aws_sns_topic.alerts_us_east_1.arn
}

output "alarm_names" {
  description = "Names of the CloudWatch metric alarms created by this module"
  value = [
    aws_cloudwatch_metric_alarm.http_5xx.alarm_name,
    aws_cloudwatch_metric_alarm.latency.alarm_name,
    aws_cloudwatch_metric_alarm.estimated_charges.alarm_name,
  ]
}

output "budget_name" {
  description = "Name of the monthly budget guard"
  value       = aws_budgets_budget.monthly.name
}

# Exercise 9.2 — Task 3: direct link to the CloudWatch dashboard
output "dashboard_url" {
  description = "Direct link to the CloudWatch dashboard"
  value       = "https://${var.aws_region}.console.aws.amazon.com/cloudwatch/home?region=${var.aws_region}#dashboards:name=${aws_cloudwatch_dashboard.main.dashboard_name}"
}
