# Resource group dédié à l'application (conteneur de plomberie, hors AVM).
resource "azurerm_resource_group" "this" {
  name     = "rg-${local.name_suffix}"
  location = var.location
  tags     = local.common_tags
}

# Log Analytics : destination des diagnostics de toutes les briques.
module "law" {
  source  = "Azure/avm-res-operationalinsights-workspace/azurerm"
  version = "0.5.1"

  name                = "log-${local.name_suffix}"
  location            = var.location
  resource_group_name = azurerm_resource_group.this.name
  enable_telemetry    = false
  tags                = local.common_tags
}

# App Service Plan (Linux).
module "plan" {
  source  = "Azure/avm-res-web-serverfarm/azurerm"
  version = "2.0.7"

  name             = "asp-${local.name_suffix}"
  location         = var.location
  parent_id        = azurerm_resource_group.this.id
  os_type          = "Linux"
  sku_name         = "B1"
  enable_telemetry = false
  tags             = local.common_tags
}

# Web App : hébergement de l'application, identité managée pour accéder aux secrets et au stockage.
module "app" {
  source  = "Azure/avm-res-web-site/azurerm"
  version = "0.22.0"

  name                     = "app-${local.name_suffix}-01"
  location                 = var.location
  parent_id                = azurerm_resource_group.this.id
  kind                     = "webapp"
  os_type                  = "Linux"
  service_plan_resource_id = module.plan.resource_id
  enable_telemetry         = false

  managed_identities = {
    system_assigned = true
  }

  diagnostic_settings = {
    to_law = {
      name                  = "to-law"
      workspace_resource_id = module.law.resource_id
      logs                  = [{ category_group = "allLogs" }]
      metrics               = [{ category = "AllMetrics" }]
    }
  }

  tags = local.common_tags
}

# Key Vault : coffre des secrets applicatifs, accès en lecture par l'identité de l'app.
module "kv" {
  source  = "Azure/avm-res-keyvault-vault/azurerm"
  version = "0.10.2"

  name                = "kv-${local.name_suffix}-01"
  location            = var.location
  resource_group_name = azurerm_resource_group.this.name
  tenant_id           = var.tenant_id
  enable_telemetry    = false

  diagnostic_settings = {
    to_law = {
      name                  = "to-law"
      workspace_resource_id = module.law.resource_id
      logs                  = [{ category_group = "allLogs" }]
      metrics               = [{ category = "AllMetrics" }]
    }
  }

  role_assignments = {
    app_secrets = {
      role_definition_id_or_name = "Key Vault Secrets User"
      principal_id               = module.app.identity_principal_id
    }
  }

  tags = local.common_tags
}

# Storage Account : fichiers déposés par les utilisateurs, accès par l'identité de l'app.
module "sa" {
  source  = "Azure/avm-res-storage-storageaccount/azurerm"
  version = "0.7.3"

  name                          = "st${local.app}${local.environment}01"
  location                      = var.location
  parent_id                     = azurerm_resource_group.this.id
  account_tier                  = "Standard"
  account_replication_type      = "LRS"
  public_network_access_enabled = false
  enable_telemetry              = false

  # Note : le module storage 0.7.3 n'expose pas d'input `diagnostic_settings` de premier niveau
  # (contrairement à web-site, serverfarm et keyvault). Diagnostics storage à câbler autrement, hors démo.

  role_assignments = {
    app_blob = {
      role_definition_id_or_name = "Storage Blob Data Contributor"
      principal_id               = module.app.identity_principal_id
    }
  }

  tags = local.common_tags
}
