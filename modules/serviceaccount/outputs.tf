locals {
  email = "${var.account_id}@${data.google_project.this.project_id}.iam.gserviceaccount.com"
}

output "member" {
  value = "serviceAccount:${local.email}"
}

output "email" {
  value = local.email
}

output "id" {
  value = google_service_account.this.id
}
