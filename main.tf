// Resource Group
resource "azurerm_resource_group" "myterraformgroup" {
  name     = "vschmitt-terraform-rg"
  location = var.location

  tags = {
    environment = "Terraform Single FortiGate"
    owner       = "vschmitt"
  }
}