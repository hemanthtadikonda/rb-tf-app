resource "aws_security_group" "main" {
  name        = "${local.name_prefix}-sg"
  description = "${local.name_prefix}-sg"
  vpc_id      = var.vpc_id
  tags = merge( local.tags , { Name = "${local.name_prefix}-sg"} )

  ingress {
    description      = "APP"
    from_port        = var.port
    to_port          = var.port
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
  port     = var.port
  protocol = "HTTP"
  vpc_id   = var.vpc_id
  tags = merge( local.tags , { Name = "${local.name_prefix}-tg"} )
}

resource "aws_lb_listener_rule" "main" {
  listener_arn = var.listener_arn
  priority     = var.priority

  action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.main.arn
  }

  condition {
    host_header {
      values = ["${var.component}-${var.env}-tadikonda.online"]
    }
  }
}

resource "aws_launch_template" "foo" {
  name = "${local.name_prefix}-template"
  image_id = data.aws_ami.ami.id
  instance_type = var.instance_type
  vpc_security_group_ids = [aws_security_group.main.id]

  user_data = filebase64(templatefile("${path.module}/example.sh", { component=var.component  }))

  tag_specifications {
    tags = {
      Name = "test"
    }
  }
}