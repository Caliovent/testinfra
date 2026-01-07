// Azure configuration
variable "subscription_id" {}
variable "client_id" {}
variable "client_secret" {}
variable "tenant_id" {}

variable "location" {
  type    = string
  default = "westus2"
}

variable "resource_group_name" {
  type    = string
  default = "vschmitt-terraform-sandwich-fgt"
}

variable "size" {
  type    = string
  default = "Standard_F2s_v2" # Recommandé pour 7.2.x
}

// License Type to create FortiGate-VM
variable "license_type" {
  default = "byol"
}

// FGT Version 7.2.9
variable "fgtversion" {
  type    = string
  default = "7.2.9"
}

variable "publisher" {
  type    = string
  default = "fortinet"
}

variable "fgtoffer" {
  type    = string
  default = "fortinet_fortigate-vm_v5"
}

variable "fgtsku" {
  type = map(any)
  default = {
    byol = "fortinet_fg-vm"
    payg = "fortinet_fg-vm_payg_2022"
  }
}

variable "adminusername" {
  type    = string
  default = "azureadmin"
}

variable "adminpassword" {
  type    = string
  default = "Fortinet123#"
}

variable "vnetcidr" {
  default = "10.1.0.0/16"
}

variable "publiccidr" {
  default = "10.1.0.0/24"
}

variable "privatecidr" {
  default = "10.1.1.0/24"
}

variable "bootstrap-fgtvm" {
  type    = string
  default = "fgtvm.conf"
}

variable "backend_size" {
  type    = string
  default = "Standard_B1s"
}

variable "management_ip" {
  type        = string
  default     = "0.0.0.0/0"
  description = "The management IP address for accessing the FortiGate VMs."
}

// License files for FGT A and FGT B
variable "license" {
  type    = string
  default = "licenseA.txt"
}

variable "license2" {
  type    = string
  default = "licenseB.txt"
}

variable "backend_ssl_key" {
  type      = string
  sensitive = true
}

variable "backend_ssl_crt" {
  type      = string
  sensitive = true
}

// --- CERTIFICATS & GODADDY ---
variable "frontend_certificate" {
  type        = string
  description = "Contenu du certificat public (PEM format)"
  sensitive   = true
  default     = ""
}

variable "frontend_private_key" {
  type        = string
  description = "Contenu de la clé privée (PEM format)"
  sensitive   = true
  default     = ""
}

variable "domain_name" {
  type        = string
  description = "Votre nom de domaine"
  default     = "mabeopsa.com"
}

variable "email" {
  type        = string
  description = "Email pour l'enregistrement Let's Encrypt"
  default     = "admin@mabeopsa.com"
}

variable "godaddy_key" {
  type        = string
  description = "Clé API GoDaddy"
  sensitive   = true
  default     = ""
}

variable "godaddy_secret" {
  type        = string
  description = "Secret API GoDaddy"
  sensitive   = true
  default     = ""
}