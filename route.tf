resource "azurerm_route_table" "internal" {
  depends_on          = [azurerm_virtual_machine.fgtvm]
  name                = "InternalRouteTable1"
  location            = azurerm_resource_group.myterraformgroup.location
  resource_group_name = azurerm_resource_group.myterraformgroup.name
}

# REMOVED: azurerm_route.azure_fabric (168.63.129.16 is restricted)

resource "azurerm_route" "default" {
  name                   = "default"
  resource_group_name    = azurerm_resource_group.myterraformgroup.name
  route_table_name       = azurerm_route_table.internal.name
  address_prefix         = "0.0.0.0/0"
  next_hop_type          = "VirtualAppliance"
  next_hop_in_ip_address = "10.1.1.7"
}

resource "azurerm_subnet_route_table_association" "internalassociate" {
  depends_on     = [azurerm_route_table.internal]
  subnet_id      = azurerm_subnet.privatesubnet.id
  route_table_id = azurerm_route_table.internal.id
}