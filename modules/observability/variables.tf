variable "alb_arn_suffix" {
  description = "ARN suffix of the ALB used as the LoadBalancer dimension on the alarms"
  type        = string
}

variable "notification_email" {
  description = "Email address subscribed to the SNS alerts topic and budget notifications"
  type        = string
}

variable "log_retention_days" {
  description = "Days to retain log group entries"
  type        = number
  default     = 14
}

variable "monthly_budget_usd" {
  description = "Monthly budget ceiling in USD"
  type        = number
  default     = 25
}

variable "estimated_charges_threshold" {
  description = "USD amount that triggers the EstimatedCharges alarm"
  type        = number
  default     = 10
}

variable "aws_region" {
  description = "AWS region for regional resources"
  type        = string
}
