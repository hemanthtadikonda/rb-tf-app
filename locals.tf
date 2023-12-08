locals {
  name_prefix = "${var.env}-${var.component}"
  tags        = merge(var.tags,{ tf-module = "app" },{ env = var.env })
  ip          = tolist(module.prometheus)

}



