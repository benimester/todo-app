variable "aws_region" {
  type        = string
  description = "The AWS region where resources will be deployed"
}

variable "project_name" {
  type        = string
  description = "The name of the project for tagging resources"
}

# -----------------------------------------------------------------------------
# VPC
# -----------------------------------------------------------------------------

variable "vpc_name" {
  type        = string
  description = "The name of the VPC to be created"
}

variable "vpc_enable_nat_gateway" {
  type        = bool
  description = "Whether to enable a NAT Gateway for private subnet internet access"
  default     = true
}

variable "vpc_private_sg_access_host" {
  type        = list(string)
  description = "The IP address of the host allowed to access the private security group"
}

variable "vpc_public_sg_access_host" {
  type        = list(string)
  description = "The IP address of the host allowed to access the public security group"
}

# -----------------------------------------------------------------------------
# Nodes
# -----------------------------------------------------------------------------

variable "node_count" {
  description = "The total number of Kubernetes worker nodes to provision"
  type        = number
}

variable "node_instance_type" {
  description = "The EC2 instance type for the Kubernetes worker nodes"
  type        = string
}

variable "ami_id" {
  description = "The AMI ID for the Kubernetes worker nodes"
  type        = string
  default     = "ami-0e2c8caa4b6378d8c" # Standard Ubuntu 24.04 LTS ID for us-east-1
}

# -----------------------------------------------------------------------------
# Bastion
# -----------------------------------------------------------------------------

variable "bastion_enable" {
  description = "Whether to enable the bastion host"
  type        = bool
}

variable "bastion_ssh_key_name" {
  description = "The name of the SSH key pair for the bastion host"
  type        = string
}

variable "bastion_ssh_key_path" {
  description = "The local path to the SSH private key for the bastion host"
  type        = string
}

# -----------------------------------------------------------------------------
# k3s
# -----------------------------------------------------------------------------

variable "k3s_cluster_token" {
  description = "The pre-shared secret token used to authenticate workers joining the K3s cluster"
  type        = string
  sensitive   = true
}

variable "secret_kubeconfig_id" {
  description = "The AWS Secrets Manager ID to store the k3s kubeconfig"
  type        = string
}

# -----------------------------------------------------------------------------
# GitHub Identity Provider
# -----------------------------------------------------------------------------

variable "github_repository" {
  description = "The GitHub repository in the format 'owner/repo' for OIDC role access"
  type        = string
}

variable "github_actions_aws_role_name" {
  description = "The name of the IAM role for GitHub Actions to assume"
  type        = string
}