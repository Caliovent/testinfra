// Resource Group
resource "azurerm_resource_group" "myterraformgroup" {
  name     = "vschmitt-terraform-single-fgt"
  location = var.location

  tags = {
    environment = "Terraform Single FortiGate"
    owner       = "vschmitt"
  }
}