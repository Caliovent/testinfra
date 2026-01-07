// Resource Group
resource "azurerm_resource_group" "myterraformgroup" {
  name     = "vschmitt-terraform-rg-v2" # Incrémenté à v2
  location = var.location

  tags = {
    environment = "Terraform Dual FortiGate - Fresh Start"
    owner       = "vschmitt"
  }
}