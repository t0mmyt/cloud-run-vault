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
  default = []
}

variable "args" {
  type    = list(string)
  default = []
}

variable "minInstances" {
  type    = number
  default = 0
}

variable "maxInstances" {
  type    = number
  default = null
}

variable "cpuLim" {
  type    = string
  default = null
}

variable "memLim" {
  type    = string
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

variable "allowUnauthenticated" {
  type    = bool
  default = false
}

variable "envs" {
  type    = map(string)
  default = {}
}

variable "secret_envs" {
  type    = map(object({ secretId : string, key : string }))
  default = {}
}

variable "secret_vols" {
  type    = map(object({ mount_path : string, secret_name : string, items : list(object({ key : string, path : string })) }))
  default = {}
}

variable "ingress" {
  type    = string
  default = "internal"
  validation {
    condition     = contains(["all", "internal", "internal-and-cloud-load-balancing"], var.ingress)
    error_message = "An invalid ingress type was passed."
  }
}

