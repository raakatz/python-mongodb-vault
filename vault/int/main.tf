module "vault" {
  source = "../modules/vault"
  kubernetes_namespace = "int"
}
