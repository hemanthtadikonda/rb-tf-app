resource "aws_security_group" "main" {
  name        = "${local.name_prefix}-sg"
  description = "${local.name_prefix}-sg"
  vpc_id      = var.default_vpc_id
  tags = merge(local.tags ,{Name ="${local.name_prefix}-sg"})

  ingress {
    description = "ALLOW ALL"
    from_port   = "9090"
    to_port     = "9090"
    protocol    = "tcp"
    cidr_blocks = [ "0.0.0.0/0" ]
  }

  egress {
    from_port        = 0
    to_port          = 0
    protocol         = "-1"
    cidr_blocks      = [ "0.0.0.0/0" ]
    ipv6_cidr_blocks = [ "::/0" ]
  }
}

resource "aws_iam_policy" "main" {
  name        = "${local.name_prefix}-policy"
  path        = "/"
  description = "${local.name_prefix}-policy"

  policy = jsonencode({
    "Version": "2012-10-17",
    "Statement": [
      {
        "Effect": "Allow",
        "Action": "ec2:Describe*",
        "Resource": "*"
      },
      {
        "Effect": "Allow",
        "Action": "elasticloadbalancing:Describe*",
        "Resource": "*"
      },
      {
        "Effect": "Allow",
        "Action": [
          "cloudwatch:ListMetrics",
          "cloudwatch:GetMetricStatistics",
          "cloudwatch:Describe*"
        ],
        "Resource": "*"
      },
      {
        "Effect": "Allow",
        "Action": "autoscaling:Describe*",
        "Resource": "*"
      }
    ]
  })
}

resource "aws_iam_role" "main" {
  name = "${local.name_prefix}-role"
  tags = merge(local.tags ,{Name ="${local.name_prefix}-role"})

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = "sts:AssumeRole"
        Effect = "Allow"
        Sid    = ""
        Principal = {
          Service = "ec2.amazonaws.com"
        }
      },
    ]
  })

}

resource "aws_iam_role_policy_attachment" "attach" {
  role       = aws_iam_role.main.name
  policy_arn = aws_iam_policy.main.arn
}

resource "aws_iam_instance_profile" "main" {
  name = "${local.name_prefix}-role"
  role = aws_iam_role.main.name
}

resource "aws_instance" "main" {
  ami           = data.aws_ami.ami.id
  instance_type = "t3.small"
  iam_instance_profile = aws_iam_instance_profile.main.name
  vpc_security_group_ids = [aws_security_group.main.id]
  tags = merge(local.tags ,{Name =local.name_prefix })

}