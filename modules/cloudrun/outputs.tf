output "url" {
  value = google_cloud_run_service.cr.status[0].url
}
