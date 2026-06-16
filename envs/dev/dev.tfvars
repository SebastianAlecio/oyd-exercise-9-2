# Nota: alb_arn_suffix ya no se define aquí. El ALB se crea en alb.tf y su
# arn_suffix real se inyecta automáticamente al módulo observability (main.tf).
aws_region                  = "us-east-2"
notification_email          = "sebastianalecio@gmail.com"
log_retention_days          = 14
monthly_budget_usd          = 25
estimated_charges_threshold = 10
