locals {
  annotations = {
    "run.googleapis.com/ingress"       = var.ingress
    "autoscaling.knative.dev/minScale" = var.minInstances
    "autoscaling.knative.dev/maxScale" = var.maxInstances
  }
}

resource "google_cloud_run_service" "cr" {
  provider = google-beta

  location = var.location
  name     = var.name
  template {
    spec {
      service_account_name = var.service_account_name
      containers {
        image   = var.image
        command = var.command
        args    = var.args

        resources {
          limits = {
            cpu    = var.cpuLim
            memory = var.memLim
          }
        }

        dynamic "ports" {
          for_each = var.ports[*]
          content {
            name           = ports.value.name
            container_port = ports.value.container_port
          }
        }

        dynamic "env" {
          for_each = var.envs
          content {
            name  = env.key
            value = env.value
          }
        }
      }
    }
  }

  metadata {
    annotations = local.annotations
  }
}

resource "google_cloud_run_service_iam_member" "noauth" {
  count = var.allowUnauthenticated ? 1 : 0

  location = var.location
  service  = google_cloud_run_service.cr.name
  member   = "allUsers"
  role     = "roles/run.invoker"
}



resource "google_cloud_run_service_iam_member" "invokers" {
  for_each = toset(var.invokers)

  location = var.location
  service  = google_cloud_run_service.cr.name
  member   = each.value
  role     = "roles/run.invoker"
}



