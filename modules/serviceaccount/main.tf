data "google_project" "this" {}

locals {
  display_name = var.display_name == "" ? var.account_id : var.display_name
}

resource "google_service_account" "this" {
  account_id   = var.account_id
  display_name = var.display_name
  description  = var.description
}
