resource "aws_security_group" "main" {
  name        = "${local.name_prefix}-sg"
  description = "${local.name_prefix}-sg"
  vpc_id      = var.vpc_id
  tags = merge( local.tags , { Name = "${local.name_prefix}-sg"} )

  ingress {
    description      = "APP"
    from_port        = var.app_port
    to_port          = var.app_port
    protocol         = "tcp"
    cidr_blocks      = var.sg_ingress_cidr
  }
  ingress {
    description      = "SSH"
    from_port        = 22
    to_port          = 22
    protocol         = "tcp"
    cidr_blocks      = var.ssh_ingress_cidr
  }
  egress {
    from_port        = 0
    to_port          = 0
    protocol         = "-1"
    cidr_blocks      = ["0.0.0.0/0"]
    ipv6_cidr_blocks = ["::/0"]
  }
}

resource "aws_lb_target_group" "main" {
  name     = "${local.name_prefix}-tg"
  port     = 80
  protocol = "HTTP"
  vpc_id   = var.vpc_id
}

resource "aws_lb_target_group" "public" {
  count = var.component == "frontend" ? 1 : 0
  name        = "${local.name_prefix}-pub"
  port        = 80
  protocol    = "HTTP"
  target_type = "ip"
  vpc_id      = var.default_vpc_id
}

resource "aws_lb_target_group_attachment" "public" {
  count            = var.component == "frontend" ? length(tolist(data.dns_a_record_set.private_lb_add.addrs)) : 0
  target_group_arn = aws_lb_target_group.public[0].arn
  target_id        = element(tolist(data.dns_a_record_set.private_lb_add.addrs), count.index )
  port             = 80
  availability_zone = "all"
}

resource "aws_route53_record" "main" {
  zone_id = var.zone_id
  name    = "${var.component}-${var.env}"
  type    = "CNAME"
  ttl     = 30
  records = [var.component == "frontend" ? var.public_alb_name : var.private_alb_name]
}


resource "aws_lb_listener_rule" "main" {
  listener_arn = var.private_alb_listener
  priority     = var.lb_priority

  action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.main.arn
  }

  condition {
    host_header {
      values = ["${var.component}-${var.env}.tadikonda.online"]
    }
  }
}

resource "aws_lb_listener_rule" "public" {
  count = var.component == "frontend" ? 1 : 0
  listener_arn = var.public_alb_listener
  priority     = 10

  action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.public[0].arn
  }

  condition {
    host_header {
      values = ["${var.component}-${var.env}.tadikonda.online"]
    }
  }
}

