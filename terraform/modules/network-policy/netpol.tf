variable "namespace" { type = string }

resource "kubernetes_network_policy" "deny_all_ingress" {
  metadata {
    name      = "deny-all-ingress"
    namespace = var.namespace
  }
  spec {
    pod_selector {}
    policy_types = ["Ingress"]
  }
}

resource "kubernetes_network_policy" "allow_same_namespace" {
  metadata {
    name      = "allow-same-namespace"
    namespace = var.namespace
  }
  spec {
    pod_selector {}
    policy_types = ["Ingress"]
    ingress {
      from {
        pod_selector {}
      }
    }
  }
}
