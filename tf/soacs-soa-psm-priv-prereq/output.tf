output "services" {
  value = [data.oci_core_services.all_oci_services.services]
}

# Output the private and public IPs of the Bastion
output "bastion-private-IPs" {
  value = [oci_core_instance.bastion.*.private_ip]
}

output "bastion-public-IPs" {
  value = [oci_core_instance.bastion.*.public_ip]
}
