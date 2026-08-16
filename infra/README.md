# Production-like infrastructure extension

The primary incident lab uses kind so incidents can be repeated cheaply and quickly. After completing the local scenarios, this directory provides a self-managed AWS extension:

```text
Terraform -> VPC, security controls, key pair, three Ubuntu EC2 nodes
Ansible   -> kernel settings, containerd, kubeadm, kubelet, kubectl, Calico
Argo CD   -> application and monitoring declarations
```

This extension creates billable AWS resources. Review `terraform plan`, restrict `admin_cidr` to your own public IP, use a disposable AWS account, and run `terraform destroy` after practice.

The topology has one control-plane node and two workers. It is useful for node operations but is not a highly available production control plane.

## Provision

```bash
cd infra/terraform/aws
cp terraform.tfvars.example terraform.tfvars
terraform init
terraform fmt -check
terraform validate
terraform plan -out=tfplan
terraform apply tfplan
```

Create `infra/ansible/inventory.ini` from the Terraform outputs, then:

```bash
cd infra/ansible
ansible all -m ping
ansible-playbook site.yml
```

Do not run incident injectors until `EXPECTED_CONTEXT` points explicitly to the disposable cluster context.
