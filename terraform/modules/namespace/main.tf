variable "name"           { type = string }
variable "environment"    { type = string }
variable "cpu_limit"      { type = string }
variable "memory_limit"   { type = string }
variable "cpu_request"    { type = string }
variable "memory_request" { type = string }
variable "max_pods"       { type = number }

resource "kubernetes_namespace" "this" {
  metadata {
    name = var.name
    labels = {
      name        = var.name
      environment = var.environment
      managed-by  = "terraform"
    }
  }
}

resource "kubernetes_resource_quota" "this" {
  metadata {
    name      = "${var.name}-quota"
    namespace = kubernetes_namespace.this.metadata[0].name
  }
  spec {
    hard = {
      "requests.cpu"    = var.cpu_request
      "requests.memory" = var.memory_request
      "limits.cpu"      = var.cpu_limit
      "limits.memory"   = var.memory_limit
      "count/pods"      = var.max_pods
    }
  }
}

resource "kubernetes_limit_range" "this" {
  metadata {
    name      = "${var.name}-limits"
    namespace = kubernetes_namespace.this.metadata[0].name
  }
  spec {
    limit {
      type = "Container"
      default         = { cpu = "200m", memory = "256Mi" }
      default_request = { cpu = "100m", memory = "128Mi" }
      max             = { cpu = "1",    memory = "1Gi"   }
    }
  }
}

output "name" { value = kubernetes_namespace.this.metadata[0].name }
