output "instance_private_ip_address" {
  value = azurerm_linux_virtual_machine.main.*.private_ip_address
}

output "ping_result" {
  value = try(jsonencode(ssh_resource.pinging[*].result), {})
}