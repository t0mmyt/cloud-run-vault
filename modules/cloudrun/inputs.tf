variable "location" {
  type = string
}

variable "name" {
  type = string
}

variable "image" {
  type = string
}

variable "ports" {
  type    = list(object({ name : string, container_port : string }))
  default = []
}

variable "command" {
  type    = list(string)
  default = null
}

variable "args" {
  type    = list(string)
  default = null
}

variable "service_account_name" {
  type    = string
  default = null
}

variable "invokers" {
  type    = list(string)
  default = []
}

variable "ingress" {
  type    = string
  default = "internal"
  validation {
    condition     = contains(["all", "internal", "internal-and-cloud-load-balancing"], var.ingress)
    error_message = "An invalid ingress type was passed."
  }
}

