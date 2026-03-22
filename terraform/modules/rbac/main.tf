variable "namespace"   { type = string }
variable "environment" { type = string }

resource "kubernetes_role" "developer" {
  metadata {
    name      = "developer"
    namespace = var.namespace
    labels    = { environment = var.environment, managed-by = "terraform" }
  }
  rule {
    api_groups = ["apps"]
    resources  = ["deployments", "replicasets"]
    verbs      = ["get", "list", "watch", "create", "update", "patch"]
  }
  rule {
    api_groups = [""]
    resources  = ["pods", "pods/logs", "services", "configmaps"]
    verbs      = ["get", "list", "watch"]
  }
}

resource "kubernetes_service_account" "deployer" {
  metadata {
    name      = "deployer"
    namespace = var.namespace
    labels    = { environment = var.environment, managed-by = "terraform" }
  }
}

resource "kubernetes_role_binding" "deployer" {
  metadata {
    name      = "deployer-binding"
    namespace = var.namespace
  }
  role_ref {
    api_group = "rbac.authorization.k8s.io"
    kind      = "Role"
    name      = kubernetes_role.developer.metadata[0].name
  }
  subject {
    kind      = "ServiceAccount"
    name      = kubernetes_service_account.deployer.metadata[0].name
    namespace = var.namespace
  }
}

output "deployer_sa" { value = kubernetes_service_account.deployer.metadata[0].name }
