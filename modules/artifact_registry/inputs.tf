data "google_project" "this" {}

variable "repositoryId" {
  type = string
}

variable "location" {
  type = string
}

variable "format" {
  type    = string
  default = "DOCKER"
  validation {
    condition     = contains(["DOCKER"], var.format)
    error_message = "Format not permitted."
  }
}

variable "iamWriters" {
  type    = list(any)
  default = []
}

variable "iamReaders" {
  type    = list(any)
  default = []
}
