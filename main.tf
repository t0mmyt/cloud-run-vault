data "google_project" "this" {}

locals {
  _ver_split = split("/", google_secret_manager_secret_version.current.id)
  config_ver = local._ver_split[length(local._ver_split) - 1]
}

module "sa-vault-server" {
  source = "./modules/serviceaccount"

  account_id  = "vault-server"
  description = "SA For Vault Server"
}


module "gcs-vault-backend" {
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

resource "google_secret_manager_secret_version" "current" {
  secret      = google_secret_manager_secret.vault-config.name
  secret_data = file("vault-server.hcl")
}

resource "google_secret_manager_secret_iam_binding" "vault-server-config" {
  members = [
    module.sa-vault-server.member
  ]
  role      = "roles/secretmanager.secretAccessor"
  secret_id = google_secret_manager_secret.vault-config.name
}

resource "google_kms_key_ring" "vault_server" {
  name     = "vault-server"
  location = "global"
}

resource "google_kms_crypto_key" "seal" {
  key_ring = google_kms_key_ring.vault_server.id
  name     = "seal"
  purpose  = "ENCRYPT_DECRYPT"
}

resource "google_kms_crypto_key_iam_binding" "seal" {
  crypto_key_id = google_kms_crypto_key.seal.id
  members = [
    module.sa-vault-server.member
  ]
  role = "roles/cloudkms.cryptoKeyEncrypterDecrypter"
}

module "vault-server" {
  source               = "./modules/cloudrun"
  image                = "australia-southeast1-docker.pkg.dev/tom-taylor-1/chr/vault:1.7.3"
  service_account_name = module.sa-vault-server.email
  location             = var.region
  name                 = "vault-server"
  ingress              = "all"
  ports = [{
    name           = null
    container_port = "8200"
  }]
  envs = {
    GOOGLE_PROJECT        = data.google_project.this.project_id
    GOOGLE_STORAGE_BUCKET = module.gcs-vault-backend.name
    SKIP_SETCAP           = true
    VAULT_KEY_RING        = google_kms_key_ring.vault_server.name
    VAULT_CRYPTO_KEY      = google_kms_crypto_key.seal.name
  }

  depends_on = [google_secret_manager_secret_version.current]
}
