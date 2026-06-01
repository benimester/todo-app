variable "kubeconfig_path" {
  description = "Path to the kubeconfig file pulled to the local machine"
  type        = string
  default     = "~/.kube/config"
}

# -----------------------------------------------------------------------------
# PostgreSQL
# -----------------------------------------------------------------------------

variable "postgres_database" {
  description = "The database name to create in PostgreSQL"
  type        = string
}

variable "postgres_username" {
  description = "The database user to create in PostgreSQL"
  type        = string
}

variable "postgres_password" {
  description = "The password for the PostgreSQL user"
  type        = string
  sensitive   = true
}

# -----------------------------------------------------------------------------
# MongoDB
# -----------------------------------------------------------------------------

variable "mongodb_database" {
  description = "The database name to create in MongoDB"
  type        = string
}

variable "mongodb_username" {
  description = "The database user to create in MongoDB"
  type        = string
}

variable "mongodb_password" {
  description = "The password for the MongoDB user"
  type        = string
  sensitive   = true
}

variable "mongodb_root_password" {
  description = "The root password for MongoDB"
  type        = string
  sensitive   = true
}

# -----------------------------------------------------------------------------
# Microservices Environment Variables
# -----------------------------------------------------------------------------

variable "jwt_secret" {
  description = "Secret key for JWT token generation"
  type        = string
  sensitive   = true
}

variable "postgres_url" {
  description = "PostgreSQL connection string (e.g. postgresql://auth_user:postgres_password@postgres:5432/auth_db)"
  type        = string
  sensitive   = true
}

variable "mongo_url" {
  description = "MongoDB connection string (e.g. mongodb://mongodb-db:27017)"
  type        = string
  sensitive   = true
}

variable "media_service_url" {
  description = "Internal URL to reach the media service (e.g. http://media-service:8000)"
  type        = string
}

variable "aws_access_key_id" {
  description = "AWS Access Key ID for S3"
  type        = string
  sensitive   = true
}

variable "aws_secret_access_key" {
  description = "AWS Secret Access Key for S3"
  type        = string
  sensitive   = true
}

variable "aws_region" {
  description = "AWS Region where the bucket is hosted"
  type        = string
  default     = "us-east-1"
}

variable "s3_bucket_name" {
  description = "Name of the S3 bucket for media uploads"
  type        = string
}

variable "aws_endpoint_url" {
  description = "Custom AWS endpoint URL (optional, e.g. for LocalStack)"
  type        = string
  default     = ""
}