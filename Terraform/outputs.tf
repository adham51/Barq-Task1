output "app_public_ip" {
  description = "Public IP of the app host"
  value       = aws_eip_association.app.public_ip
}

output "db_public_ip" {
  description = "Public IP of the db host (SSH only)"
  value       = aws_eip_association.db.public_ip
}

output "db_private_ip" {
  description = "Private IP of the db host, used by the app to reach Postgres"
  value       = aws_instance.db.private_ip
}

# Used by deploy.sh: terraform output -raw ansible_inventory > ../ansible/inventory.ini
output "ansible_inventory" {
  description = "Ansible inventory built from the values above"
  value       = <<-EOT
    [app]
    app ansible_host=${aws_eip_association.app.public_ip}

    [db]
    db ansible_host=${aws_eip_association.db.public_ip}

    [all:vars]
    ansible_user=ubuntu
    db_host=${aws_instance.db.private_ip}
  EOT
}
