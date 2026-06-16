# Task 3 — the module must accept the us-east-1 provider alias so the
# EstimatedCharges alarm can reach the AWS/Billing namespace.
terraform {
  required_providers {
    aws = {
      source                = "hashicorp/aws"
      version               = "~> 5.0"
      configuration_aliases = [aws.us_east_1]
    }
  }
}

# ---------------------------------------------------------------------------
# Task 1 — Log group and SNS
# ---------------------------------------------------------------------------
resource "aws_cloudwatch_log_group" "finapi" {
  name              = "/finapi/dev"
  retention_in_days = var.log_retention_days
}

resource "aws_sns_topic" "alerts" {
  name = "finapi-alerts"
}

resource "aws_sns_topic_subscription" "email" {
  topic_arn = aws_sns_topic.alerts.arn
  protocol  = "email"
  endpoint  = var.notification_email
}

# A CloudWatch alarm can only trigger an SNS topic in its OWN region. The
# EstimatedCharges alarm (Task 3) lives in us-east-1, so it needs a topic that
# also lives in us-east-1 — the default-region topic above cannot be referenced
# cross-region (AWS rejects it with "Invalid region ... specified").
resource "aws_sns_topic" "alerts_us_east_1" {
  provider = aws.us_east_1
  name     = "finapi-alerts-us-east-1"
}

resource "aws_sns_topic_subscription" "email_us_east_1" {
  provider  = aws.us_east_1
  topic_arn = aws_sns_topic.alerts_us_east_1.arn
  protocol  = "email"
  endpoint  = var.notification_email
}

# ---------------------------------------------------------------------------
# Task 2 — HTTP 5xx and latency alarms
# ---------------------------------------------------------------------------
resource "aws_cloudwatch_metric_alarm" "http_5xx" {
  alarm_name          = "finapi-http-5xx"
  alarm_description   = "Fires when the ALB returns 5 or more HTTP 5xx responses in 2 consecutive minutes"
  namespace           = "AWS/ApplicationELB"
  metric_name         = "HTTPCode_Target_5XX_Count"
  dimensions          = { LoadBalancer = var.alb_arn_suffix }
  statistic           = "Sum"
  period              = 60
  evaluation_periods  = 2
  threshold           = 5
  comparison_operator = "GreaterThanOrEqualToThreshold"
  treat_missing_data  = "notBreaching"

  alarm_actions = [aws_sns_topic.alerts.arn]
  ok_actions    = [aws_sns_topic.alerts.arn]
}

resource "aws_cloudwatch_metric_alarm" "latency" {
  alarm_name          = "finapi-target-latency"
  alarm_description   = "Fires when the ALB target response time averages 1 second or more"
  namespace           = "AWS/ApplicationELB"
  metric_name         = "TargetResponseTime"
  dimensions          = { LoadBalancer = var.alb_arn_suffix }
  statistic           = "Average"
  period              = 60
  evaluation_periods  = 2
  threshold           = 1
  comparison_operator = "GreaterThanOrEqualToThreshold"
  treat_missing_data  = "notBreaching"

  alarm_actions = [aws_sns_topic.alerts.arn]
  ok_actions    = [aws_sns_topic.alerts.arn]
}

# ---------------------------------------------------------------------------
# Task 3 — EstimatedCharges alarm (billing metrics live in us-east-1)
# ---------------------------------------------------------------------------
resource "aws_cloudwatch_metric_alarm" "estimated_charges" {
  provider = aws.us_east_1

  alarm_name          = "finapi-estimated-charges"
  alarm_description   = "Near-real-time alert when estimated account charges cross the threshold"
  namespace           = "AWS/Billing"
  metric_name         = "EstimatedCharges"
  dimensions          = { Currency = "USD" }
  statistic           = "Maximum"
  period              = 86400
  evaluation_periods  = 1
  threshold           = var.estimated_charges_threshold
  comparison_operator = "GreaterThanOrEqualToThreshold"

  # Must reference the us-east-1 topic (same region as this alarm).
  alarm_actions = [aws_sns_topic.alerts_us_east_1.arn]
}

# ---------------------------------------------------------------------------
# Task 4 — Monthly budget guard
# ---------------------------------------------------------------------------
resource "aws_budgets_budget" "monthly" {
  name         = "finapi-monthly-budget"
  budget_type  = "COST"
  time_unit    = "MONTHLY"
  limit_amount = var.monthly_budget_usd
  limit_unit   = "USD"

  notification {
    comparison_operator        = "GREATER_THAN"
    threshold                  = 80
    threshold_type             = "PERCENTAGE"
    notification_type          = "ACTUAL"
    subscriber_email_addresses = [var.notification_email]
  }
}

# ---------------------------------------------------------------------------
# Exercise 9.2 — Task 1 & 2: single CloudWatch dashboard for the on-call team
# ---------------------------------------------------------------------------
# Request volume, error rate, and the 5xx alarm state in one view. The body is
# built with jsonencode() (no heredoc strings). Every metric widget references
# Terraform expressions (var.alb_arn_suffix, var.aws_region) and the alarm
# widget references the resource attribute aws_cloudwatch_metric_alarm.http_5xx.arn
# — no hardcoded ARNs or account IDs.
resource "aws_cloudwatch_dashboard" "main" {
  dashboard_name = "finapi-dashboard"

  dashboard_body = jsonencode({
    widgets = [
      # Widget 1 — ALB request volume
      {
        type   = "metric"
        x      = 0
        y      = 0
        width  = 8
        height = 6
        properties = {
          title   = "ALB Request Count"
          view    = "timeSeries"
          stacked = false
          region  = var.aws_region
          stat    = "Sum"
          period  = 300
          metrics = [
            ["AWS/ApplicationELB", "RequestCount", "LoadBalancer", var.alb_arn_suffix]
          ]
        }
      },
      # Widget 2 — HTTP 5xx error count
      {
        type   = "metric"
        x      = 8
        y      = 0
        width  = 8
        height = 6
        properties = {
          title   = "HTTP 5xx Count"
          view    = "timeSeries"
          stacked = false
          region  = var.aws_region
          stat    = "Sum"
          period  = 300
          metrics = [
            ["AWS/ApplicationELB", "HTTPCode_Target_5XX_Count", "LoadBalancer", var.alb_arn_suffix]
          ]
        }
      },
      # Widget 3 — team's choice: live status of the HTTP 5xx alarm
      {
        type   = "alarm"
        x      = 16
        y      = 0
        width  = 8
        height = 6
        properties = {
          title = "HTTP 5xx Alarm State"
          alarms = [
            aws_cloudwatch_metric_alarm.http_5xx.arn
          ]
        }
      },
      # Widget 4 — live request volume that actually carries data in this setup.
      # The ALB uses a fixed-response listener (no target group), so request
      # volume is published as HTTP_Fixed_Response_Count, not RequestCount.
      {
        type   = "metric"
        x      = 0
        y      = 6
        width  = 8
        height = 6
        properties = {
          title   = "ALB Fixed-Response Requests"
          view    = "timeSeries"
          stacked = false
          region  = var.aws_region
          stat    = "Sum"
          period  = 300
          metrics = [
            ["AWS/ApplicationELB", "HTTP_Fixed_Response_Count", "LoadBalancer", var.alb_arn_suffix]
          ]
        }
      }
    ]
  })
}
