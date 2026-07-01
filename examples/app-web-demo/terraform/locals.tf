locals {
  app         = "webapp"
  environment = "qua"
  name_suffix = "${local.app}-${local.environment}"

  common_tags = {
    environment   = "qualification"
    owner         = "squad-demo"
    "cost-center" = "a-remplacer"
    project       = "app-web-demo"
  }
}
