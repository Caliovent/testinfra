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
  default = "terraform-sandwich-fgt"
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

// License files for FGT A and FGT B
variable "license" {
  type    = string
  default = "licenseA.txt"
}

variable "license2" {
  type    = string
  default = "licenseB.txt"
}