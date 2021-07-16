terraform {
  required_version = "~>1.0.2"
  backend "remote" {}
}

provider "google" {
  region = "australia-southeast1"
}

provider "google-beta" {
  region = "australia-southeast1"
}
