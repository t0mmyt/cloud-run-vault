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

module "sa-vault-gcp-auth" {
  source = "./modules/serviceaccount"

  account_id  = "vault-gcp-auth"
  description = "SA for Vault GCP Auth"
}

resource "google_project_iam_custom_role" "vault-gcp-auth" {
  role_id = "VaultGcpAuth"
  title   = "Vault GCP Auth"
  permissions = [
    "iam.serviceAccounts.get",
    "iam.serviceAccountKeys.get"
  ]
}

resource "google_project_iam_binding" "vault-gcp-auth" {
  members = [
    module.sa-vault-server.member
  ]
  role = google_project_iam_custom_role.vault-gcp-auth.id
}

module "cloudrun" {
  source               = "app.terraform.io/tom-dev/cloudrun/google"
  version              = "0.0.2"
  maxInstances         = 1
  allowUnauthenticated = true
  image                = "australia-southeast1-docker.pkg.dev/tom-taylor-1/chr/vault:1.7.3"
  service_account_name = module.sa-vault-server.email
  location             = var.region
  name                 = "vault-server"
  ingress              = "all"
  cpuLim               = "1000m"
  memLim               = "512Mi"
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
    VAULT_API_ADDR        = "https://vault-server-nis46fe7fa-ts.a.run.app"
  }

  depends_on = [google_secret_manager_secret_version.current]
}

module "sa-vault-demo" {
  source = "./modules/serviceaccount"

  account_id  = "vault-demo"
  description = "SA for Vault GCP Auth Demo"
}

module "cr-vault-demo" {
  source               = "app.terraform.io/tom-dev/cloudrun/google"
  version              = "0.0.2"
  maxInstances         = 1
  allowUnauthenticated = false
  image                = "australia-southeast1-docker.pkg.dev/tom-taylor-1/chr/vault-demo:0.1"
  service_account_name = module.sa-vault-demo.email
  location             = var.region
  name                 = "vault-demo"
  ingress              = "all"
  cpuLim               = "1000m"
  memLim               = "512Mi"
//  envs = {
//    GOOGLE_PROJECT        = data.google_project.this.project_id
//    GOOGLE_STORAGE_BUCKET = module.gcs-vault-backend.name
//    SKIP_SETCAP           = true
//    VAULT_KEY_RING        = google_kms_key_ring.vault_server.name
//    VAULT_CRYPTO_KEY      = google_kms_crypto_key.seal.name
//  }
  depends_on = [google_secret_manager_secret_version.current]
}

resource "google_service_account_iam_binding" "vault-signing" {
  members = [
    module.sa-vault-demo.member
  ]
  role = "roles/iam.serviceAccountTokenCreator"
  service_account_id = module.sa-vault-demo.id
}
