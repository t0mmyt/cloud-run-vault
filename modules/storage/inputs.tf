variable "name" {
  type = string
}

variable "location" {
  type = string
}

variable "admins" {
  type    = list(string)
  default = []
}
