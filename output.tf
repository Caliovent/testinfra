output "ResourceGroup" {
  value = azurerm_resource_group.myterraformgroup.name
}

output "LoadBalancer_Public_IP" {
  value       = azurerm_public_ip.elb_pip.ip_address
  description = "L'adresse IP publique du Load Balancer (l'origine pour Front Door)"
}

output "Azure_Front_Door_Endpoint" {
  value       = "https://${azurerm_cdn_frontdoor_endpoint.my_endpoint.host_name}"
  description = "URL du point de terminaison Front Door par défaut"
}

output "FrontDoor_CNAME_Target" {
  value       = azurerm_cdn_frontdoor_endpoint.my_endpoint.host_name
  description = "La valeur cible pour votre enregistrement CNAME (ex: www -> cette valeur)"
}

output "FrontDoor_DNS_Validation_Token" {
  value       = azurerm_cdn_frontdoor_custom_domain.my_custom_domain.validation_token
  description = "La valeur du jeton de validation pour l'enregistrement TXT (_dnsauth.mabeopsa.com)"
}

output "Backend_Server_Private_IP" {
  value       = azurerm_network_interface.backend_nic.private_ip_address
  description = "IP privée du serveur Backend pour la configuration de la VIP FortiGate"
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