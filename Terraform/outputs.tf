output "app_public_ip" {
  description = "Public IP of the app host"
  value       = aws_instance.app.public_ip
}

output "db_public_ip" {
  description = "Public IP of the db host (SSH only)"
  value       = aws_instance.db.public_ip
}

output "db_private_ip" {
  description = "Private IP of the db host, used by the app to reach Postgres"
  value       = aws_instance.db.private_ip
}

# Used by deploy.sh: terraform output -raw ansible_inventory > ../ansible/inventory/hosts.ini
output "ansible_inventory" {
  description = "Ansible inventory built from the values above"
  value       = <<-EOT
    [app]
    app1 ansible_host=${aws_instance.app.public_ip}

    [db]
    db1 ansible_host=${aws_instance.db.public_ip}

    [all:vars]
    db_host=${aws_instance.db.private_ip}
    ansible_user=ubuntu
    ansible_ssh_private_key_file=${var.private_key_path}
  EOT
}
