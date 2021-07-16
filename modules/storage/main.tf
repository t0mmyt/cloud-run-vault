resource "google_storage_bucket" "bucket" {
  name     = var.name
  location = var.location
}

resource "google_storage_bucket_iam_member" "admins" {
  for_each = toset(var.admins)

  bucket = google_storage_bucket.bucket.name
  member = each.value
  role   = "roles/storage.admin"
}
