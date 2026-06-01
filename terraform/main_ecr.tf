# -----------------------------------------------------------------------------
# ECR
# -----------------------------------------------------------------------------

module "ecr_repositories" {
  source   = "terraform-aws-modules/ecr/aws"
  version  = "~> 2.3"
  for_each = var.ecr_enable ? toset(var.microservices) : []

  repository_name = each.value

  repository_force_delete         = true
  repository_image_tag_mutability = "MUTABLE"
  repository_image_scan_on_push   = true

  repository_encryption_type = "KMS"

  create_lifecycle_policy = true
  repository_lifecycle_policy = jsonencode({
    rules = [
      {
        rulePriority = 1
        description  = "Keep only the last 3 images to control storage costs"
        selection = {
          tagStatus   = "any"
          countType   = "imageCountMoreThan"
          countNumber = 3
        }
        action = {
          type = "expire"
        }
      }
    ]
  })

  tags = {
    Project = var.project_name
  }
}