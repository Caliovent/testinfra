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

// --- AZURE LOAD BALANCER (Frontend for Front Door) ---

// Public IP for the ELB
resource "azurerm_public_ip" "elb_pip" {
  name                = "ELB-PublicIP"
  location            = var.location
  resource_group_name = azurerm_resource_group.myterraformgroup.name
  allocation_method   = "Static"
  sku                 = "Standard" # Required for Front Door backend compatibility
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

// Health Probe (Critical for preventing drops)
resource "azurerm_lb_probe" "elb_probe" {
  loadbalancer_id = azurerm_lb.elb.id
  name            = "tcp-probe-8008"
  port            = 8008
  protocol        = "Tcp"
}

// LB Rule (Load balance all traffic or specific ports)
resource "azurerm_lb_rule" "lbnatrule" {
  loadbalancer_id = azurerm_lb.elb.id
  name            = "LBRule-HTTPS"
  protocol        = "Tcp"

  # CORRECTION: Ports MUST be 443 for HTTPS traffic
  frontend_port = 443
  backend_port  = 443

  frontend_ip_configuration_name = "LoadBalancerFrontEnd"
  probe_id                       = azurerm_lb_probe.elb_probe.id
  backend_address_pool_ids       = [azurerm_lb_backend_address_pool.elb_backend.id]

  # CRITICAL: Enable Floating IP so packets arrive with Destination IP = Public IP
  enable_floating_ip = true
}

// --- NETWORK SECURITY GROUPS ---

resource "azurerm_network_security_group" "publicnetworknsg" {
  name                = "PublicNetworkSecurityGroup"
  location            = var.location
  resource_group_name = azurerm_resource_group.myterraformgroup.name

  # NEW RULE: Allow Azure Load Balancer Probes
  security_rule {
    name                       = "AllowAzureLoadBalancer"
    priority                   = 150
    direction                  = "Inbound"
    access                     = "Allow"
    protocol                   = "*"
    source_port_range          = "*"
    destination_port_range     = "*"
    source_address_prefix      = "AzureLoadBalancer"
    destination_address_prefix = "*"
  }

  security_rule {
    name                       = "AllowFrontDoor"
    priority                   = 100
    direction                  = "Inbound"
    access                     = "Allow"
    protocol                   = "Tcp"
    source_port_range          = "*"
    destination_port_range     = "*"
    source_address_prefix      = "AzureFrontDoor.Backend"
    destination_address_prefix = "*"
  }

  security_rule {
    name                       = "AllowManagement"
    priority                   = 200
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
    name                       = "AllowAllInbound"
    priority                   = 1001
    direction                  = "Inbound"
    access                     = "Allow"
    protocol                   = "*"
    source_port_range          = "*"
    destination_port_range     = "*"
    source_address_prefix      = "*"
    destination_address_prefix = "*"
  }
}

// --- INTERFACES (Count = 2 for FGT A and FGT B) ---

// Public IPs for Management of each FGT
resource "azurerm_public_ip" "fgt_mgmt_pip" {
  count               = 2
  name                = "FGT-${count.index + 1}-Mgmt-PIP"
  location            = var.location
  resource_group_name = azurerm_resource_group.myterraformgroup.name
  allocation_method   = "Static"
  sku                 = "Standard"
}

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

    // We need a public IP for management of each unit independently
    public_ip_address_id = azurerm_public_ip.fgt_mgmt_pip[count.index].id
  }
}

// Port 2 (Private / Internal)
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

// Connect NSGs
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

// Associate Port 1 to the Load Balancer Backend Pool
// Note: In some designs, Port 1 is Mgmt only and traffic hits Port 2 via Internal LB. 
// But here we adhere to "FrontDoor -> ELB -> FGT", so ELB hits the External Interface.
resource "azurerm_network_interface_backend_address_pool_association" "fgt_to_elb" {
  count                   = 2
  network_interface_id    = azurerm_network_interface.fgtport1[count.index].id
  ip_configuration_name   = "ipconfig1"
  backend_address_pool_id = azurerm_lb_backend_address_pool.elb_backend.id
}

// --- AZURE INTERNAL LOAD BALANCER (For Return Traffic) ---

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