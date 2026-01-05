# Configuration Cloud-Init pour installer Nginx et forcer TLS 1.2
locals {
  custom_data_script = templatefile("${path.module}/webserver.conf", {})
}

resource "azurerm_network_interface" "backend_nic" {
  name                = "backend-nic"
  location            = var.location
  resource_group_name = azurerm_resource_group.myterraformgroup.name

  ip_configuration {
    name                          = "internal"
    subnet_id                     = azurerm_subnet.privatesubnet.id
    private_ip_address_allocation = "Dynamic"
  }
}

resource "azurerm_linux_virtual_machine" "backend_vm" {
  name                = "Backend-Web-Server"
  resource_group_name = azurerm_resource_group.myterraformgroup.name
  location            = var.location
  size                = var.backend_size
  admin_username      = var.adminusername
  network_interface_ids = [
    azurerm_network_interface.backend_nic.id,
  ]

  admin_password                  = var.adminpassword
  disable_password_authentication = false

  os_disk {
    caching              = "ReadWrite"
    storage_account_type = "Standard_LRS"
  }

  source_image_reference {
    publisher = "Canonical"
    offer     = "0001-com-ubuntu-server-jammy"
    sku       = "22_04-lts"
    version   = "latest"
  }

  custom_data = base64encode(local.custom_data_script)

  tags = {
    environment = "Backend TLS 1.2"
  }
}
