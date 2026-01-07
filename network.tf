// Create Virtual Network
resource "azurerm_virtual_network" "fgtvnetwork" {
  name                = "fgtvnetwork"
  address_space       = [var.vnetcidr]
  location            = var.location
  resource_group_name = azurerm_resource_group.myterraformgroup.name
}

resource "azurerm_subnet" "publicsubnet" {
  name                 = "publicSubnet"
  resource_group_name  = azurerm_resource_group.myterraformgroup.name
  virtual_network_name = azurerm_virtual_network.fgtvnetwork.name
  address_prefixes     = [var.publiccidr]
}

resource "azurerm_subnet" "privatesubnet" {
  name                 = "privateSubnet"
  resource_group_name  = azurerm_resource_group.myterraformgroup.name
  virtual_network_name = azurerm_virtual_network.fgtvnetwork.name
  address_prefixes     = [var.privatecidr]
}

// --- AZURE LOAD BALANCER ---

resource "azurerm_public_ip" "elb_pip" {
  name                = "ELB-PublicIP"
  location            = var.location
  resource_group_name = azurerm_resource_group.myterraformgroup.name
  allocation_method   = "Static"
  sku                 = "Standard"
}

resource "azurerm_lb" "elb" {
  name                = "External-LB"
  location            = var.location
  resource_group_name = azurerm_resource_group.myterraformgroup.name
  sku                 = "Standard"

  frontend_ip_configuration {
    name                 = "LoadBalancerFrontEnd"
    public_ip_address_id = azurerm_public_ip.elb_pip.id
  }
}

resource "azurerm_lb_backend_address_pool" "elb_backend" {
  loadbalancer_id = azurerm_lb.elb.id
  name            = "FortiGateBackendPool"
}

resource "azurerm_lb_probe" "elb_probe" {
  loadbalancer_id = azurerm_lb.elb.id
  name            = "tcp-probe-8008"
  port            = 8008
  protocol        = "Tcp"
}

# RÈGLE 1 : HTTPS (Port 443)
resource "azurerm_lb_rule" "lbnatrule_https" {
  loadbalancer_id                = azurerm_lb.elb.id
  name                           = "LBRule-HTTPS"
  protocol                       = "Tcp"
  frontend_port                  = 443
  backend_port                   = 443
  frontend_ip_configuration_name = "LoadBalancerFrontEnd"
  probe_id                       = azurerm_lb_probe.elb_probe.id
  backend_address_pool_ids       = [azurerm_lb_backend_address_pool.elb_backend.id]
  enable_floating_ip             = true
}

# RÈGLE 2 : HTTP (Port 80) - NÉCESSAIRE POUR LA SONDE AFD
resource "azurerm_lb_rule" "lbnatrule_http" {
  loadbalancer_id                = azurerm_lb.elb.id
  name                           = "LBRule-HTTP"
  protocol                       = "Tcp"
  frontend_port                  = 80
  backend_port                   = 80
  frontend_ip_configuration_name = "LoadBalancerFrontEnd"
  probe_id                       = azurerm_lb_probe.elb_probe.id
  backend_address_pool_ids       = [azurerm_lb_backend_address_pool.elb_backend.id]
  enable_floating_ip             = true
}

// --- NETWORK SECURITY GROUPS ---

resource "azurerm_network_security_group" "publicnetworknsg" {
  name                = "PublicNetworkSecurityGroup"
  location            = var.location
  resource_group_name = azurerm_resource_group.myterraformgroup.name

  # Priorité 100 : Autoriser explicitement les sondes de Front Door
  security_rule {
    name                       = "AllowFrontDoorInbound"
    priority                   = 100
    direction                  = "Inbound"
    access                     = "Allow"
    protocol                   = "Tcp"
    source_port_range          = "*"
    destination_port_ranges    = ["80", "443"]
    source_address_prefix      = "AzureFrontDoor.Backend"
    destination_address_prefix = "*"
  }

  # Priorité 110 : Autoriser les sondes du Load Balancer (Port 8008 et autres)
  security_rule {
    name                       = "AllowAzureLoadBalancerInbound"
    priority                   = 110
    direction                  = "Inbound"
    access                     = "Allow"
    protocol                   = "*"
    source_port_range          = "*"
    destination_port_range     = "*"
    source_address_prefix      = "AzureLoadBalancer"
    destination_address_prefix = "*"
  }

  # Priorité 120 : Management (SSH, GUI)
  security_rule {
    name                       = "AllowAdminManagement"
    priority                   = 120
    direction                  = "Inbound"
    access                     = "Allow"
    protocol                   = "Tcp"
    source_port_range          = "*"
    destination_port_ranges    = ["22", "80", "443", "8443"]
    source_address_prefix      = var.management_ip
    destination_address_prefix = "*"
  }
}

resource "azurerm_network_security_group" "privatenetworknsg" {
  name                = "PrivateNetworkSecurityGroup"
  location            = var.location
  resource_group_name = azurerm_resource_group.myterraformgroup.name

  security_rule {
    name                       = "AllowAllInternal"
    priority                   = 100
    direction                  = "Inbound"
    access                     = "Allow"
    protocol                   = "*"
    source_port_range          = "*"
    destination_port_range     = "*"
    source_address_prefix      = "10.1.0.0/16"
    destination_address_prefix = "*"
  }
}

// --- INTERFACES & ASSOCIATIONS ---

resource "azurerm_network_interface" "fgtport1" {
  count               = 2
  name                = "fgt-instance-${count.index + 1}-port1"
  location            = var.location
  resource_group_name = azurerm_resource_group.myterraformgroup.name

  ip_configuration {
    name                          = "ipconfig1"
    subnet_id                     = azurerm_subnet.publicsubnet.id
    private_ip_address_allocation = "Dynamic"
    primary                       = true
    public_ip_address_id          = azurerm_public_ip.fgt_mgmt_pip[count.index].id
  }
}

resource "azurerm_network_interface" "fgtport2" {
  count                          = 2
  name                           = "fgt-instance-${count.index + 1}-port2"
  location                       = var.location
  resource_group_name            = azurerm_resource_group.myterraformgroup.name
  ip_forwarding_enabled          = true
  accelerated_networking_enabled = true
  ip_configuration {
    name                          = "ipconfig1"
    subnet_id                     = azurerm_subnet.privatesubnet.id
    private_ip_address_allocation = "Dynamic"
  }
}

resource "azurerm_network_interface_security_group_association" "port1nsg" {
  count                     = 2
  network_interface_id      = azurerm_network_interface.fgtport1[count.index].id
  network_security_group_id = azurerm_network_security_group.publicnetworknsg.id
}

resource "azurerm_network_interface_security_group_association" "port2nsg" {
  count                     = 2
  network_interface_id      = azurerm_network_interface.fgtport2[count.index].id
  network_security_group_id = azurerm_network_security_group.privatenetworknsg.id
}

resource "azurerm_network_interface_backend_address_pool_association" "fgt_to_elb" {
  count                   = 2
  network_interface_id    = azurerm_network_interface.fgtport1[count.index].id
  ip_configuration_name   = "ipconfig1"
  backend_address_pool_id = azurerm_lb_backend_address_pool.elb_backend.id
}

// --- INTERNAL LOAD BALANCER ---

resource "azurerm_lb" "ilb" {
  name                = "Internal-LB"
  location            = var.location
  resource_group_name = azurerm_resource_group.myterraformgroup.name
  sku                 = "Standard"
  frontend_ip_configuration {
    name                          = "LoadBalancerFrontEnd"
    subnet_id                     = azurerm_subnet.privatesubnet.id
    private_ip_address_allocation = "Dynamic"
  }
}

resource "azurerm_lb_backend_address_pool" "ilb_backend" {
  loadbalancer_id = azurerm_lb.ilb.id
  name            = "FortiGateBackendPool-Internal"
}

resource "azurerm_lb_probe" "ilb_probe" {
  loadbalancer_id = azurerm_lb.ilb.id
  name            = "tcp-probe-8008-internal"
  port            = 8008
  protocol        = "Tcp"
}

resource "azurerm_lb_rule" "ilb_rule" {
  loadbalancer_id                = azurerm_lb.ilb.id
  name                           = "ILBRule"
  protocol                       = "All"
  frontend_port                  = 0
  backend_port                   = 0
  frontend_ip_configuration_name = "LoadBalancerFrontEnd"
  probe_id                       = azurerm_lb_probe.ilb_probe.id
  backend_address_pool_ids       = [azurerm_lb_backend_address_pool.ilb_backend.id]
}

resource "azurerm_network_interface_backend_address_pool_association" "fgt_to_ilb" {
  count                   = 2
  network_interface_id    = azurerm_network_interface.fgtport2[count.index].id
  ip_configuration_name   = "ipconfig1"
  backend_address_pool_id = azurerm_lb_backend_address_pool.ilb_backend.id
}

resource "azurerm_public_ip" "fgt_mgmt_pip" {
  count               = 2
  name                = "FGT-${count.index + 1}-Mgmt-PIP"
  location            = var.location
  resource_group_name = azurerm_resource_group.myterraformgroup.name
  allocation_method   = "Static"
  sku                 = "Standard"
}