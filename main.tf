// Resource Group

resource "azurerm_resource_group" "myterraformgroup" {
  name     = "terraform-single-fgt"
  location = var.location

  tags = {
    environment = "Terraform Single FortiGate"
  }
}


data "azurerm_client_config" "current" {}

resource "azurerm_key_vault" "kv" {
  name                        = "kv-sandwich-${substr(var.subscription_id, 0, 8)}" # Must be globally unique
  location                    = var.location
  resource_group_name         = azurerm_resource_group.myterraformgroup.name
  enabled_for_deployment      = true
  enabled_for_disk_encryption = true
  tenant_id                   = data.azurerm_client_config.current.tenant_id
  soft_delete_retention_days  = 7
  purge_protection_enabled    = false

  sku_name = "standard"

  access_policy {
    tenant_id = data.azurerm_client_config.current.tenant_id
    object_id = data.azurerm_client_config.current.object_id

    certificate_permissions = [
      "Get", "List", "Update", "Create", "Import", "Delete", "Recover", "Backup", "Restore", "ManageContacts", "ManageIssuers", "GetIssuers", "ListIssuers", "SetIssuers", "DeleteIssuers"
    ]

    secret_permissions = [
      "Get", "List", "Set", "Delete", "Recover", "Backup", "Restore"
    ]
  }
}

# Allow Front Door Service Principal to read the Key Vault
resource "azurerm_role_assignment" "afd_kv_read" {
  scope                = azurerm_key_vault.kv.id
  role_definition_name = "Key Vault Secret User"
  principal_id         = "205478c0-bd50-4e91-8969-556509b5522e" # Fixed Object ID for Azure Front Door Service Principal
  # Note: Sometimes you need to look up the specific SP for your tenant if the fixed ID doesn't work.
}