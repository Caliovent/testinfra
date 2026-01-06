resource "random_id" "front_door_endpoint_name" {
  byte_length = 4
}

locals {
  front_door_profile_name      = "afd-profile-${random_id.front_door_endpoint_name.hex}"
  front_door_endpoint_name     = "afd-${random_id.front_door_endpoint_name.hex}"
  front_door_origin_group_name = "afd-origin-group"
  front_door_origin_name       = "afd-origin-elb"
  front_door_route_name        = "afd-route"
}

resource "azurerm_cdn_frontdoor_profile" "my_front_door" {
  name                = local.front_door_profile_name
  resource_group_name = azurerm_resource_group.myterraformgroup.name
  sku_name            = "Standard_AzureFrontDoor"
}

resource "azurerm_cdn_frontdoor_endpoint" "my_endpoint" {
  name                     = local.front_door_endpoint_name
  cdn_frontdoor_profile_id = azurerm_cdn_frontdoor_profile.my_front_door.id
}
resource "azurerm_cdn_frontdoor_origin_group" "my_origin_group" {
  name                     = local.front_door_origin_group_name
  cdn_frontdoor_profile_id = azurerm_cdn_frontdoor_profile.my_front_door.id
  session_affinity_enabled = false

  load_balancing {
    sample_size                 = 4
    successful_samples_required = 3
  }

  health_probe {
    path                = "/health"
    protocol            = "Http" # Probe via HTTP to avoid SSL errors
    interval_in_seconds = 100
  }
}

resource "azurerm_cdn_frontdoor_origin" "my_app_origin" {
  name                          = local.front_door_origin_name
  cdn_frontdoor_origin_group_id = azurerm_cdn_frontdoor_origin_group.my_origin_group.id
  enabled                       = true

  host_name          = azurerm_public_ip.elb_pip.ip_address
  origin_host_header = "Backend-Web-Server.e14mag0lr13eplu30y0rxqtsib.xx.internal.cloudapp.net"
  http_port          = 80
  https_port         = 443
  priority           = 1
  weight             = 1000

  # N/A for HTTP, but kept for config consistency
  certificate_name_check_enabled = false
}

resource "azurerm_cdn_frontdoor_route" "my_route" {
  name                          = local.front_door_route_name
  cdn_frontdoor_endpoint_id     = azurerm_cdn_frontdoor_endpoint.my_endpoint.id
  cdn_frontdoor_origin_group_id = azurerm_cdn_frontdoor_origin_group.my_origin_group.id
  cdn_frontdoor_origin_ids      = [azurerm_cdn_frontdoor_origin.my_app_origin.id]

  supported_protocols    = ["Http", "Https"]
  patterns_to_match      = ["/*"]
  forwarding_protocol    = "HttpOnly" # Force HTTP to backend to bypass SSL validation
  link_to_default_domain = true
  https_redirect_enabled = true
}