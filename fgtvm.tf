resource "azurerm_virtual_machine" "fgtvm" {
  count               = 2
  name                = "FGT-Instance-${count.index == 0 ? "A" : "B"}"
  location            = var.location
  resource_group_name = azurerm_resource_group.myterraformgroup.name
  network_interface_ids = [
    azurerm_network_interface.fgtport1[count.index].id,
    azurerm_network_interface.fgtport2[count.index].id
  ]
  primary_network_interface_id = azurerm_network_interface.fgtport1[count.index].id
  vm_size                      = var.size

  delete_os_disk_on_termination    = true
  delete_data_disks_on_termination = true

  storage_image_reference {
    publisher = var.publisher
    offer     = var.fgtoffer
    sku       = var.license_type == "byol" ? var.fgtsku["byol"] : var.fgtsku["payg"]
    version   = var.fgtversion
  }

  plan {
    name      = var.license_type == "byol" ? var.fgtsku["byol"] : var.fgtsku["payg"]
    publisher = var.publisher
    product   = var.fgtoffer
  }

  storage_os_disk {
    name              = "osDisk-${count.index}"
    caching           = "ReadWrite"
    managed_disk_type = "Standard_LRS"
    create_option     = "FromImage"
  }

  storage_data_disk {
    name              = "datadisk-${count.index}"
    managed_disk_type = "Standard_LRS"
    create_option     = "Empty"
    lun               = 0
    disk_size_gb      = "30"
  }

  os_profile {
    computer_name  = "fgt-${count.index == 0 ? "A" : "B"}"
    admin_username = var.adminusername
    admin_password = var.adminpassword

    // Inject License A for Index 0, License B for Index 1
    custom_data = templatefile("${var.bootstrap-fgtvm}", {
      type         = var.license_type
      license_file = count.index == 0 ? var.license : var.license2
      hostname     = count.index == 0 ? "FGT-A" : "FGT-B"
    })
  }

  os_profile_linux_config {
    disable_password_authentication = false
  }

  boot_diagnostics {
    enabled     = true
    storage_uri = azurerm_storage_account.fgtstorageaccount.primary_blob_endpoint
  }

  tags = {
    environment = "Terraform Dual FGT"
  }
}