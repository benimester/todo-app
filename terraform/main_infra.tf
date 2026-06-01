# -----------------------------------------------------------------------------
# VPC
# -----------------------------------------------------------------------------
module "vpc" {
  source  = "terraform-aws-modules/vpc/aws"
  version = "~> 5.0"

  name = var.vpc_name
  cidr = "10.0.0.0/16"

  azs             = ["us-east-1a"]
  public_subnets  = ["10.0.1.0/24"]
  private_subnets = ["10.0.10.0/24"]

  enable_nat_gateway   = var.vpc_enable_nat_gateway
  single_nat_gateway   = true
  enable_dns_hostnames = true
  enable_dns_support   = true

  create_igw = true

  tags = {
    Project = var.project_name
    Name    = var.vpc_name
  }
}

# -----------------------------------------------------------------------------
# Security Group for Private Subnet
# -----------------------------------------------------------------------------
resource "aws_security_group" "private_sg" {
  name        = "private-subnet-sg"
  description = "Allow inbound SSH and Kubernetes API traffic"
  vpc_id      = module.vpc.vpc_id

  ingress {
    description = "Allow SSH"
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = var.vpc_private_sg_access_host
  }

  ingress {
    description = "Allow Kubernetes"
    from_port   = 6443
    to_port     = 6443
    protocol    = "tcp"
    cidr_blocks = var.vpc_private_sg_access_host
  }

  ingress {
    description = "Allow Flannel VXLAN"
    from_port   = 8472
    to_port     = 8472
    protocol    = "udp"
    cidr_blocks = var.vpc_private_sg_access_host
  }

  ingress {
    description     = "Allow HTTP from Bastion"
    from_port       = 80
    to_port         = 80
    protocol        = "tcp"
    security_groups = [aws_security_group.public_sg.id]
  }

  ingress {
      description     = "Allow NodePort HTTP from Bastion"
      from_port       = 30080
      to_port         = 30080
      protocol        = "tcp"
      security_groups = [aws_security_group.public_sg.id]
    }

  egress {
    description = "Allow all outbound traffic"
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Project = var.project_name
    Name    = "private-sg"
  }
}

# -----------------------------------------------------------------------------
# Security Group for Public Subnet
# -----------------------------------------------------------------------------
resource "aws_security_group" "public_sg" {
  name        = "public-subnet-sg"
  description = "Allow inbound SSH from your IP and web traffic"
  vpc_id      = module.vpc.vpc_id

  ingress {
    description = "Secure SSH Access"
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = var.vpc_public_sg_access_host
  }

  ingress {
    description = "Allow HTTP"
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = var.vpc_public_sg_access_host
  }

  ingress {
    description = "Allow HTTPS"
    from_port   = 443
    to_port     = 443
    protocol    = "tcp"
    cidr_blocks = var.vpc_public_sg_access_host
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Project = var.project_name
    Name    = "public-sg"
  }
}

# -----------------------------------------------------------------------------
# Nodes
# -----------------------------------------------------------------------------

# Secret Manager

resource "aws_secretsmanager_secret" "k3s_kubeconfig" {
  name                    = var.secret_kubeconfig_id
  recovery_window_in_days = 0
}

resource "aws_iam_role" "role_ec2_assume_principal_role" {
  name = "role-assume-principal-role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = "sts:AssumeRole"
        Effect = "Allow"
        Principal = {
          Service = "ec2.amazonaws.com"
        }
      }
    ]
  })
}

resource "aws_iam_role_policy_attachment" "systems_manager_policy_attachment" {
  role       = aws_iam_role.role_ec2_assume_principal_role.name
  policy_arn = "arn:aws:iam::aws:policy/AmazonSSMManagedInstanceCore"
}

resource "aws_iam_policy" "write_kubeconfig" {
  name        = "write-kubeconfig-policy"
  description = "Allows K3s master to update its kubeconfig in Secrets Manager"

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect   = "Allow"
        Action   = ["secretsmanager:PutSecretValue"]
        Resource = [aws_secretsmanager_secret.k3s_kubeconfig.arn]
      }
    ]
  })
}

resource "aws_iam_role_policy_attachment" "node_master_write_secret" {
  role       = aws_iam_role.role_ec2_assume_principal_role.name
  policy_arn = aws_iam_policy.write_kubeconfig.arn
}

resource "aws_iam_instance_profile" "master_node_profile" {
  name = "master-node-instance-profile"
  role = aws_iam_role.role_ec2_assume_principal_role.name
}

resource "aws_instance" "node-master" {
  ami                    = var.ami_id
  instance_type          = var.node_instance_type
  subnet_id              = module.vpc.private_subnets[0]
  vpc_security_group_ids = [aws_security_group.private_sg.id]
  key_name               = var.bastion_ssh_key_name

  iam_instance_profile = aws_iam_instance_profile.master_node_profile.name

  depends_on = [module.vpc]

  user_data = templatefile("${path.module}/scripts/master.sh", {
    token     = var.k3s_cluster_token
    secret_id = var.secret_kubeconfig_id
    region    = var.aws_region
  })

  tags = {
    Project = var.project_name
    Name    = "node-master"
    Role    = "master"
  }
}

resource "aws_instance" "k8s_worker" {
  count                  = var.node_count
  ami                    = var.ami_id
  instance_type          = var.node_instance_type
  subnet_id              = module.vpc.private_subnets[0]
  vpc_security_group_ids = [aws_security_group.private_sg.id]
  key_name               = var.bastion_ssh_key_name

  depends_on = [module.vpc]

  user_data = templatefile("${path.module}/scripts/worker.sh", {
    token     = var.k3s_cluster_token
    master_ip = aws_instance.node-master.private_ip
  })

  tags = {
    Project = var.project_name
    Name    = "node-worker-${count.index + 1}"
    Role    = "worker"
  }
}

# -----------------------------------------------------------------------------
# Bastion
# -----------------------------------------------------------------------------

resource "aws_key_pair" "k8s_key" {
  key_name   = var.bastion_ssh_key_name
  public_key = file(var.bastion_ssh_key_path)
}

resource "aws_instance" "bastion" {
  count         = var.bastion_enable ? 1 : 0
  instance_type = "t3.micro"
  ami           = var.ami_id

  subnet_id              = module.vpc.public_subnets[0]
  vpc_security_group_ids = [aws_security_group.public_sg.id]

  key_name                    = var.bastion_ssh_key_name
  associate_public_ip_address = true

  user_data = templatefile("${path.module}/scripts/bastion.sh", {
    node_ips = concat(
      [aws_instance.node-master.private_ip],
      aws_instance.k8s_worker[*].private_ip
    )
  })

  tags = {
    Project = var.project_name
    Name    = "bastion"
  }
}

resource "aws_eip" "bastion_eip" {
  count    = var.bastion_enable ? 1 : 0
  instance = aws_instance.bastion[0].id
  domain   = "vpc"

  tags = {
    Project = var.project_name
    Name    = "bastion-eip"
  }
}

# -----------------------------------------------------------------------------
# GitHub Identity Provider
# -----------------------------------------------------------------------------

resource "aws_iam_openid_connect_provider" "github_oidc" {
  url            = "https://token.actions.githubusercontent.com"
  client_id_list = ["sts.amazonaws.com"]
}
resource "aws_iam_role" "github_actions_role" {
  name = "github-actions-role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Principal = {
          Federated = aws_iam_openid_connect_provider.github_oidc.arn
        }
        Action = "sts:AssumeRoleWithWebIdentity"
        Condition = {
          StringLike = {
            "token.actions.githubusercontent.com:sub" : "repo:${var.github_repository}:*"
          }
          StringEquals = {
            "token.actions.githubusercontent.com:aud" : "sts.amazonaws.com"
          }
        }
      }
    ]
  })
}

# ECR Policies
resource "aws_iam_policy" "ecr_publish_policy" {
  name        = "github-actions-ecr-policy"
  description = "Allows GitHub Actions to push images to ECR"

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Sid      = "GetAuthToken"
        Effect   = "Allow"
        Action   = "ecr:GetAuthorizationToken"
        Resource = "*"
      },
      {
        Sid    = "PushToECR"
        Effect = "Allow"
        Action = [
          "ecr:CompleteLayerUpload",
          "ecr:UploadLayerPart",
          "ecr:InitiateLayerUpload",
          "ecr:BatchCheckLayerAvailability",
          "ecr:PutImage",
          "ecr:BatchGetImage",
          "ecr:GetDownloadUrlForLayer"
        ]
        Resource = [for service in var.microservices : "arn:aws:ecr:${var.aws_region}:*:repository/${service}"]
      }
    ]
  })
}

resource "aws_iam_role_policy_attachment" "attach_ecr_policy" {
  role       = aws_iam_role.github_actions_role.name
  policy_arn = aws_iam_policy.ecr_publish_policy.arn
}

# SSM Port Forwarding policies
resource "aws_iam_policy" "ssm_port_forwarding_policy" {
  name        = "github-actions-ssm-policy"
  description = "Allows GitHub Actions to start SSM sessions for port forwarding"

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Sid    = "StartSession"
        Effect = "Allow"
        Action = "ssm:StartSession"
        Resource = [
          "arn:aws:ec2:${var.aws_region}:*:instance/*",
          "arn:aws:ssm:*:*:document/AWS-StartPortForwardingSession"
        ]
      },
      {
        Sid      = "TerminateOwnSession"
        Effect   = "Allow"
        Action   = "ssm:TerminateSession"
        Resource = "arn:aws:ssm:${var.aws_region}:*:session/$${aws:username}-*"
      },
      {
        Sid      = "DescribeInstancesForDiscovery"
        Effect   = "Allow"
        Action   = "ec2:DescribeInstances"
        Resource = "*"
      }
    ]
  })
}

resource "aws_iam_role_policy_attachment" "attach_ssm_policy" {
  role       = aws_iam_role.github_actions_role.name
  policy_arn = aws_iam_policy.ssm_port_forwarding_policy.arn
}

# Secret Manager access

resource "aws_iam_policy" "secretsmanager_policy" {
  name        = "github-actions-secretsmanager-policy"
  description = "Allows GitHub Actions to retrieve the Kubeconfig file"

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Sid      = "GetKubeconfigSecret"
        Effect   = "Allow"
        Action   = "secretsmanager:GetSecretValue"
        Resource = "arn:aws:secretsmanager:${var.aws_region}:*:secret:*"
      }
    ]
  })
}

resource "aws_iam_role_policy_attachment" "attach_secretsmanager" {
  role       = aws_iam_role.github_actions_role.name
  policy_arn = aws_iam_policy.secretsmanager_policy.arn
}
