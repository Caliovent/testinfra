locals {
  custom_data_script = templatefile("${path.module}/webserver.conf", {
    domain_name          = "mabeopsa.com" # Or use a variable if you prefer
    frontend_certificate = var.frontend_certificate
    frontend_private_key = var.frontend_private_key
  })
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