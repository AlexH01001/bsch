variable "app" {
    default = "bosch"
    description = "Project name, which it will be used in concatenation with other variables to obtain a more unique name for the resources"
}

variable "location" {
  default = "eastus"
  description = "Location where the resources will be spawned."
}

variable "vm_number" {
  default = 2
  description = "Number of virtual machines to be created"
}

variable "address_space_vnet" {
  default = ["10.0.0.0/16"]
  description = "Address space for the virtual network"
}

variable "subnet_address_space" {
  default = ["10.0.0.0/24"]
  description = "Subnet address space"
}

variable "allocation_method_pub_ip" {
  default = "Static"
  description = "Allocation method for public ip static/dynamic"
}
variable "allocation_method_private_ip" {
  default = "Dynamic"
  description = "Allocation method for private ip static/dynamic"
}

variable az_vm_size {
  default = "Standard_B1s"
}

variable "admin_user" {
  default = "azadmin"
  description = "Admin user for the Virtual Machines"
}


