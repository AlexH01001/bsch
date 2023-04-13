terraform {
  required_providers {
    azurerm = {
      source = "hashicorp/azurerm"
      version = "3.51.0"
    }
    ssh = {
      source = "loafoe/ssh"
    }
  }
}

provider "azurerm" {
  # Configuration options
  features {}
}

#Create resource group
resource "azurerm_resource_group" "main" {
    name = "${var.app}-rg-${var.location}"
    location = var.location
}

#Create virtual network
resource "azurerm_virtual_network" "main" {
  name = "${var.app}-vnet-${var.location}"
  location = azurerm_resource_group.main.location
  resource_group_name = azurerm_resource_group.main.name
  address_space = var.address_space_vnet
}

#Create subnet
resource "azurerm_subnet" "main" {
  name = "${var.app}-subnet-${var.location}"
  virtual_network_name = azurerm_virtual_network.main.name
  resource_group_name = azurerm_resource_group.main.name
  address_prefixes = var.subnet_address_space
}

#Create public ip address
resource "azurerm_public_ip" "external" {
  count = var.vm_number
  name = "${var.app}-${count.index}-public-ip"
  location = var.location
  resource_group_name = azurerm_resource_group.main.name
  allocation_method = var.allocation_method_pub_ip
  sku = "Standard"
}

#Create Network Security Group and Rule
resource "azurerm_network_security_group" "nsg" {
  name = "${var.app}-nsg"
  location = var.location
  resource_group_name = azurerm_resource_group.main.name
  security_rule {
    name = "SSH"
    priority = 1001
    direction = "Inbound"
    access = "Allow"
    protocol = "Tcp"
    
    source_port_range = "*"
    destination_port_range = "22"
    source_address_prefix = "*"
    destination_address_prefix = "*"
  }
}

#Create network interface card (NIC)
resource "azurerm_network_interface" "internal" {
  count = var.vm_number

  name = "${var.app}-nic-${count.index}-int-${var.location}"
  location = azurerm_resource_group.main.location
  resource_group_name = azurerm_resource_group.main.name
  
  ip_configuration {
    name = "internal"
    subnet_id = azurerm_subnet.main.id
    private_ip_address_allocation = var.allocation_method_private_ip
    
    public_ip_address_id = element(azurerm_public_ip.external.*.id, count.index)
  }
}

#Create NSG for subnet
resource "azurerm_subnet_network_security_group_association" "nsg_assoc" {
  subnet_id = azurerm_subnet.main.id
  network_security_group_id = azurerm_network_security_group.nsg.id
}

#Create random password for admin user
resource "random_password" "admin_password" {
  count = var.vm_number
  length = 10
  lower = true
  upper = true
  numeric = true
}

#Create virtual machines
resource "azurerm_linux_virtual_machine" "main" {
  count = var.vm_number

  name = "${var.app}-vm${count.index}-${var.location}"
  resource_group_name = azurerm_resource_group.main.name
  location = azurerm_resource_group.main.location
  size = var.az_vm_size
  admin_username = var.admin_user
  admin_password = random_password.admin_password[count.index].result
  disable_password_authentication = false

  network_interface_ids = [element(azurerm_network_interface.internal.*.id, count.index)]
  
  os_disk {
    caching = "ReadWrite"
    storage_account_type = "Standard_LRS"
  }

  source_image_reference {
    publisher = "Canonical"
    offer = "UbuntuServer"
    sku = "16.04-LTS"
    version = "latest"
  }
}

resource "ssh_resource" "pinging" {
  count = var.vm_number
  depends_on = [
    azurerm_linux_virtual_machine.main
  ]
  host = azurerm_linux_virtual_machine.main[count.index].public_ip_address
  user = azurerm_linux_virtual_machine.main[count.index].admin_username
  password = azurerm_linux_virtual_machine.main[count.index].admin_password
  agent = false
  file {
    content = <<-EOF
    first_address=${azurerm_linux_virtual_machine.main[0].private_ip_address}
    last_address=${azurerm_linux_virtual_machine.main[var.vm_number - 1].private_ip_address}
    current_address=${azurerm_linux_virtual_machine.main[count.index].private_ip_address}
    addresses=${jsonencode(azurerm_linux_virtual_machine.main[*].private_ip_address)}

    for (( i=0; i<${var.vm_number}; ++i))
    do
      if [ $i == 0 ]
      then
        ip_list[$i]=$(echo $addresses | cut -d ',' -f1 | cut -d '[' -f2)
      elif [ $i == ${var.vm_number - 1} ]
      then
        ip_list[$i]=$(echo $addresses | cut -d ',' -f${var.vm_number} | cut -d ']' -f1)
      else
        ip_list[$i]=$(echo $addresses | cut -d ',' -f$((i+1)))
      fi
    done
    
    next_address=$${ip_list[${count.index} + 1 ]}

    if [ $current_address == $last_address ]
    then
      ping -c 1 $first_address &>/dev/null
      if [[ $? == 0 ]]
      then
        echo "VM[${count.index}] pinged successfully VM[0]"
      else
        echo "VM[${count.index}] couldn't ping VM[0]"
      fi
    else
      ping -c 1 $next_address &>/dev/null
      if [[ $? == 0 ]]
      then
        echo "VM[${count.index}] pinged successfully VM[${count.index + 1}]"
      else
        echo "VM[${count.index}] couldn't ping VM[${count.index + 1}]"
      fi
    fi
    EOF
    destination = "/tmp/ping.sh"
    permissions = "0700"

  }
  commands = [
    "sudo apt-get update",
    "sudo apt-get install dos2unix -y",
    "dos2unix /tmp/ping.sh",
    "/tmp/ping.sh",
  ]
  timeout = "2m"
}