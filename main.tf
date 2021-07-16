data "google_project" "this" {}

module sa-vault-server {
  source = "./modules/serviceaccount"

  account_id  = "vault-server"
  description = "SA For Vault Server"
}


module gcs-vault-backend {
  source = "./modules/storage"

  name     = "${data.google_project.this.project_id}-vault"
  location = var.region
  admins = [
    module.sa-vault-server.member
  ]
}

resource "google_secret_manager_secret" "vault-config" {
  secret_id = "vault-config"
  replication {
    automatic = true
  }
}
