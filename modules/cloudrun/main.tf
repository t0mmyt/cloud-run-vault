resource "google_cloud_run_service" "cr" {
  location = var.location
  name     = var.name
  template {
    spec {
      service_account_name = var.service_account_name
      containers {
        image   = var.image
        command = var.command
        args    = var.args
        dynamic "ports" {
          for_each = var.ports[*]
          content {
            name           = ports.value.name
            container_port = ports.value.container_port
          }
        }
      }
    }
  }

  metadata {
    annotations = {
      "run.googleapis.com/ingress" = var.ingress
    }
  }
}

resource "google_cloud_run_service_iam_member" "invokers" {
  for_each = toset(var.invokers)

  location = var.location
  service  = google_cloud_run_service.cr.name
  member   = each.value
  role     = "roles/run.invoker"
}
