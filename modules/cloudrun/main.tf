locals {
  annotations = {
    "run.googleapis.com/ingress"       = var.ingress
    "autoscaling.knative.dev/minScale" = "1"
    "run.googleapis.com/launch-stage"  = "BETA"
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
            cpu : "2000m"
            memory : "2G"
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

        dynamic "env" {
          for_each = var.secret_envs
          content {
            name = env.key
            value_from {
              secret_key_ref {
                name = env.value.secretId
                key  = env.value.key
              }
            }
          }
        }

        dynamic "volume_mounts" {
          for_each = var.secret_vols

          content {
            name       = volume_mounts.key
            mount_path = volume_mounts.value.mount_path
          }
        }

      }

      dynamic "volumes" {
        for_each = var.secret_vols

        content {
          name = volumes.key
          secret {
            secret_name = volumes.value.secret_name
            dynamic "items" {
              for_each = volumes.value.items

              content {
                key  = items.value.key
                path = items.value.path
              }
            }
          }
        }
      }

    }
  }

  metadata {
    annotations = local.annotations
  }
}

resource "google_cloud_run_service_iam_member" "invokers" {
  for_each = toset(var.invokers)

  location = var.location
  service  = google_cloud_run_service.cr.name
  member   = each.value
  role     = "roles/run.invoker"
}



