resource "google_artifact_registry_repository" "repo" {
  provider      = google-beta
  format        = var.format
  repository_id = var.repositoryId
  location      = var.location
}

resource "google_artifact_registry_repository_iam_member" "readers" {
  for_each = toset(var.iamReaders)

  provider   = google-beta
  member     = each.key
  repository = google_artifact_registry_repository.repo.name
  location   = var.location
  role       = "roles/artifactregistry.reader"
}

resource "google_artifact_registry_repository_iam_member" "writers" {
  for_each = toset(var.iamWriters)

  provider   = google-beta
  member     = each.key
  repository = google_artifact_registry_repository.repo.name
  location   = var.location
  role       = "roles/artifactregistry.writer"
}
