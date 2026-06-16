# ---------------------------------------------------------------------------
# Application Load Balancer (ALB) — traffic source for the dashboard
# ---------------------------------------------------------------------------
# Task 4 requires generating real traffic so that at least one dashboard widget
# shows a data point. This ALB sits on the default VPC with a fixed-response
# listener (HTTP 200). Its `arn_suffix` is wired into the observability module,
# so every alarm and dashboard widget references the load balancer.

data "aws_vpc" "default" {
  default = true
}

data "aws_subnets" "default" {
  filter {
    name   = "vpc-id"
    values = [data.aws_vpc.default.id]
  }
  filter {
    name   = "default-for-az"
    values = ["true"]
  }
}

resource "aws_security_group" "alb" {
  name        = "finapi-alb-sg"
  description = "Allow inbound HTTP to the FinAPI ALB"
  vpc_id      = data.aws_vpc.default.id

  ingress {
    description = "HTTP from anywhere"
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  egress {
    description = "All outbound"
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
}

resource "aws_lb" "finapi" {
  name               = "finapi-alb"
  internal           = false
  load_balancer_type = "application"
  security_groups    = [aws_security_group.alb.id]
  subnets            = data.aws_subnets.default.ids
}

resource "aws_lb_listener" "http" {
  load_balancer_arn = aws_lb.finapi.arn
  port              = 80
  protocol          = "HTTP"

  default_action {
    type = "fixed-response"

    fixed_response {
      content_type = "text/plain"
      message_body = "FinAPI OK"
      status_code  = "200"
    }
  }
}
