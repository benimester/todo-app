output "aws_region" {
  value       = var.aws_region
  description = "The AWS region where resources will be deployed."
  sensitive   = false
}

output "aws_account_id" {
  value       = data.aws_caller_identity.current.account_id
  description = "The authenticated AWS Account ID."
}

output "project_name" {
  value       = var.project_name
  description = "The name of the project for tagging resources."
}

# -----------------------------------------------------------------------------
# VPC
# -----------------------------------------------------------------------------

output "vpc_name" {
  value       = var.vpc_name
  description = "The name of the VPC to be created."
}

output "vpc_enable_nat_gateway" {
  value       = var.vpc_enable_nat_gateway
  description = "Whether to enable a NAT Gateway for private subnet internet access."
}

output "vpc_private_sg_access_host" {
  value       = var.vpc_private_sg_access_host
  description = "The IP address of the host allowed to access the private security group."
}

output "vpc_public_sg_access_host" {
  value       = var.vpc_public_sg_access_host
  description = "The IP address of the host allowed to access the public security group."
}

# -----------------------------------------------------------------------------
# Nodes
# -----------------------------------------------------------------------------

output "node_count" {
  value       = var.node_count
  description = "The total number of Kubernetes worker nodes to provision."
}

output "node_instance_type" {
  value       = var.node_instance_type
  description = "The EC2 instance type for the Kubernetes worker nodes."
}

# -----------------------------------------------------------------------------
# Bastion
# -----------------------------------------------------------------------------

output "bastion_enable" {
  value       = var.bastion_enable
  description = "Whether to provision a bastion host for secure access to private resources."
}

output "bastion_ssh_key_name" {
  value       = var.bastion_ssh_key_name
  description = "The name of the SSH key pair for the bastion host."
  depends_on  = [var.bastion_enable]
}

output "bastion_ssh_key_path" {
  value       = var.bastion_ssh_key_path
  description = "The local file path to the SSH private key for the bastion host."
  depends_on  = [var.bastion_enable]
}

output "bastion_public_ip" {
  value       = var.bastion_enable ? aws_instance.bastion[0].public_ip : null
  description = "The public IP address of the bastion host for SSH access."
  depends_on  = [var.bastion_enable]
}

# -----------------------------------------------------------------------------
# k3s
# -----------------------------------------------------------------------------

output "k3s_token_set" {
  value       = var.k3s_cluster_token != "" ? "True" : "False"
  description = "Indicates whether a k3s cluster token has been set for secure node joining."
  sensitive   = true
}

# -----------------------------------------------------------------------------
# GitHub Identity Provider
# -----------------------------------------------------------------------------

output "github_repository" {
  value       = var.github_repository
  description = "The GitHub repository in the format 'owner/repo' for OIDC role access"
}

output "github_actions_aws_role_name" {
  value       = var.github_actions_aws_role_name
  description = "The name of the AWS IAM Role created for GitHub Actions OIDC access"
}
