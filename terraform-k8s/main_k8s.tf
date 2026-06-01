# -----------------------------------------------------------------------------
# PostgreSQL
# -----------------------------------------------------------------------------

resource "helm_release" "postgres" {
  name             = "postgres-db"
  chart            = "oci://registry-1.docker.io/bitnamicharts/postgresql"
  namespace        = "default"
  create_namespace = true

  set {
    name  = "auth.database"
    value = var.postgres_database
  }
  set {
    name  = "auth.username"
    value = var.postgres_username
  }
  set {
    name  = "auth.password"
    value = var.postgres_password
  }

  # --- Minimal Resource Constraints ---
  set {
    name  = "primary.resources.requests.cpu"
    value = "100m"
  }
  set {
    name  = "primary.resources.requests.memory"
    value = "256Mi"
  }
  set {
    name  = "primary.resources.limits.cpu"
    value = "500m"
  }
  set {
    name  = "primary.resources.limits.memory"
    value = "384Mi"
  }

  set {
    name  = "primary.extendedConfiguration"
    value = "max_connections = 20\nshared_buffers = 64MB\nwork_mem = 4MB\nmaintenance_work_mem = 16MB"
  }
}

# -----------------------------------------------------------------------------
# MongoDB
# -----------------------------------------------------------------------------

resource "helm_release" "mongodb" {
  name             = "mongodb-db"
  chart            = "oci://registry-1.docker.io/bitnamicharts/mongodb"
  namespace        = "default"
  create_namespace = true

  set {
    name  = "auth.rootUser"
    value = "root"
  }
  set {
    name  = "auth.rootPassword"
    value = var.mongodb_root_password
  }
  set {
    name  = "auth.database"
    value = var.mongodb_database
  }
  set {
    name  = "auth.username"
    value = "user"
  }
  set {
    name  = "auth.password"
    value = "password"
  }

  # --- Minimal Resource Constraints ---
  set {
    name  = "resources.requests.cpu"
    value = "100m"
  }
  set {
    name  = "resources.requests.memory"
    value = "256Mi"
  }
  set {
    name  = "resources.limits.cpu"
    value = "500m"
  }
  set {
    name  = "resources.limits.memory"
    value = "384Mi"
  }

  set {
    name  = "extraFlags[0]"
    value = "--wiredTigerCacheSizeGB=0.25"
  }
}


# -----------------------------------------------------------------------------
# Config Map and App Secret
# -----------------------------------------------------------------------------

resource "kubernetes_config_map" "auth_config" {
  metadata {
    name      = "auth-config"
    namespace = "default"
  }

  data = {
    INIT = "true"
  }
}

resource "kubernetes_config_map" "todo_config" {
  metadata {
    name      = "todo-config"
    namespace = "default"
  }

  data = {
    MEDIA_SERVICE_URL = var.media_service_url
  }
}

resource "kubernetes_config_map" "media_config" {
  metadata {
    name      = "media-config"
    namespace = "default"
  }

  data = {
    AWS_REGION       = var.aws_region
    S3_BUCKET_NAME   = var.s3_bucket_name
  }
}

resource "kubernetes_secret" "auth_secret" {
  metadata {
    name      = "auth-secret"
    namespace = "default"
  }

  data = {
    JWT_SECRET   = var.jwt_secret
    POSTGRES_URL = "postgresql://${var.postgres_username}:${var.postgres_password}@postgres-db-postgresql:5432/${var.postgres_database}"
  }

  type = "Opaque"
}

resource "kubernetes_secret" "todo_secret" {
  metadata {
    name      = "todo-secret"
    namespace = "default"
  }

  data = {
    JWT_SECRET = var.jwt_secret
    MONGO_URL  = "mongodb://root:${var.mongodb_root_password}@mongodb-db.default.svc.cluster.local:27017/${var.mongodb_database}?authSource=admin"
  }

  type = "Opaque"
}

resource "kubernetes_secret" "media_secret" {
  metadata {
    name      = "media-secret"
    namespace = "default"
  }

  data = {
    AWS_ACCESS_KEY_ID     = var.aws_access_key_id
    AWS_SECRET_ACCESS_KEY = var.aws_secret_access_key
  }

  type = "Opaque"
}

resource "helm_release" "nginx_ingress" {
  name             = "ingress-nginx"
  repository       = "https://kubernetes.github.io/ingress-nginx"
  chart            = "ingress-nginx"
  namespace        = "ingress-nginx"
  create_namespace = true

  set {
    name  = "controller.service.type"
    value = "NodePort"
  }

  set {
    name  = "controller.service.nodePorts.http"
    value = "30080"
  }
}
