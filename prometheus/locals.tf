locals {
  name_prefix = "prometheus-${var.env}"
  tags = merge(var.tags , {tf-module} = "prometheus")
}

