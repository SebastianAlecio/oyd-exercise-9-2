# Task 5 — call the observability module here
module "observability" {
  source = "./modules/observability"

  # Wire the REAL ALB created in alb.tf (its arn_suffix) into the module so the
  # alarms and dashboard widgets reference an actual load balancer with traffic.
  alb_arn_suffix              = aws_lb.finapi.arn_suffix
  notification_email          = var.notification_email
  log_retention_days          = var.log_retention_days
  monthly_budget_usd          = var.monthly_budget_usd
  estimated_charges_threshold = var.estimated_charges_threshold
  aws_region                  = var.aws_region

  providers = {
    aws           = aws
    aws.us_east_1 = aws.us_east_1
  }
}
