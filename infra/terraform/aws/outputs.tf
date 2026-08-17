output "control_plane_public_ip" {
  description = "Public IP for the disposable control-plane node."
  value       = aws_instance.node[0].public_ip
}

output "worker_public_ips" {
  description = "Public IPs for disposable worker nodes."
  value       = slice(aws_instance.node[*].public_ip, 1, 3)
}

output "control_plane_private_ip" {
  description = "Private API advertise address used by kubeadm."
  value       = aws_instance.node[0].private_ip
}

output "ansible_inventory" {
  description = "Inventory skeleton; save it as infra/ansible/inventory.ini."
  value       = <<-EOT
    [control_plane]
    control ansible_host=${aws_instance.node[0].public_ip} private_ip=${aws_instance.node[0].private_ip}

    [workers]
    worker1 ansible_host=${aws_instance.node[1].public_ip} private_ip=${aws_instance.node[1].private_ip}
    worker2 ansible_host=${aws_instance.node[2].public_ip} private_ip=${aws_instance.node[2].private_ip}

    [k8s_cluster:children]
    control_plane
    workers
  EOT
}
