output "ResourceGroup" {
  value = azurerm_resource_group.myterraformgroup.name
}

output "LoadBalancer_Public_IP" {
  value       = azurerm_public_ip.elb_pip.ip_address
  description = "The IP address Front Door points to (ELB Frontend)"
}

# output "Azure_Front_Door_Endpoint" {
#   value       = "https://${azurerm_cdn_frontdoor_endpoint.my_endpoint.host_name}"
#   description = "Use this URL to test the full flow"
# }

output "Backend_Server_Private_IP" {
  value       = azurerm_network_interface.backend_nic.private_ip_address
  description = "Target IP for your FortiGate Policy (VIP/D-NAT)"
}

output "FGT_A_Management_URL" {
  value = format("https://%s:8443", azurerm_public_ip.fgt_mgmt_pip[0].ip_address)
}

output "FGT_B_Management_URL" {
  value = format("https://%s:8443", azurerm_public_ip.fgt_mgmt_pip[1].ip_address)
}

output "Username" {
  value = var.adminusername
}

output "Password" {
  value = var.adminpassword
}