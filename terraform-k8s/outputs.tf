# -----------------------------------------------------------------------------
# PostgreSQL
# -----------------------------------------------------------------------------

output "postgres_info" {
  description = "PostgreSQL credentials and info"
  value = {
    database = var.postgres_database
    username = var.postgres_username
  }
}

# -----------------------------------------------------------------------------
# MongoDB
# -----------------------------------------------------------------------------

output "mongodb_info" {
  description = "MongoDB credentials and info"
  value = {
    database = var.mongodb_database
    username = "root"
  }
}

# -----------------------------------------------------------------------------
# Microservices Env Vars Info
# -----------------------------------------------------------------------------

output "microservices_config" {
  description = "Non-sensitive microservices configuration values"
  value = {
    media_service_url = var.media_service_url
    aws_region        = var.aws_region
    s3_bucket_name    = var.s3_bucket_name
  }
}