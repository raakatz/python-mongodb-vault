# CHANGE TO MONGO

resource "vault_mount" "db" {
  path = "database"
  type = "database"
}

resource "vault_database_secret_backend_connection" "mysql" {
  backend           = vault_mount.db.path
  name              = "my_database"
  allowed_roles     = ["webapp"]
  plugin_name       = "mysql-database-plugin"
  verify_connection = false

  mysql {
    connection_url = "{{username}}:{{password}}@tcp(myapp-${var.kubernetes_namespace}-mysql.myapp-${var.kubernetes_namespace}.svc:3306)/"
    username       = "root"
    password       = "willBeChangedByVault"
  }
}

resource "vault_database_secret_backend_role" "role" {
  backend             = vault_mount.db.path
  name                = "webapp"
  db_name             = vault_database_secret_backend_connection.mysql.name
  creation_statements = ["CREATE USER '{{name}}'@'%' IDENTIFIED BY '{{password}}';GRANT ALL PRIVILEGES ON my_database.* TO '{{name}}'@'%';"]
  default_ttl         = 3600
  max_ttl             = 86400
}
