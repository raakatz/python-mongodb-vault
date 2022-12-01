resource "vault_auth_backend" "kubernetes" {
  type = "kubernetes"
}

resource "vault_kubernetes_auth_backend_config" "kubernetes" {
  backend                = vault_auth_backend.kubernetes.path
  kubernetes_host        = "https://kubernetes.default.svc:443"
  disable_iss_validation = "true"
}

resource "vault_kubernetes_auth_backend_role" "webapp-role" {
  backend                          = vault_auth_backend.kubernetes.path
  role_name                        = "webapp"
  bound_service_account_names      = ["webapp-sa"]
  bound_service_account_namespaces = ["myapp-${var.kubernetes_namespace}"]
  token_ttl                        = 3600
  token_max_ttl                    = 86400
  token_policies                   = ["webapp"]
}
