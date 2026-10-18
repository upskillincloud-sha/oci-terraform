variable "tenancy_ocid" {
  type = string
}

variable "user_ocid" {
  type = string
}

variable "fingerprint" {
  type = string
}

variable "private_key_path" {
  type        = string
  description = "Path to the OCI API private key (.pem). Never commit the key itself."
}

variable "region" {
  type    = string
  default = "eu-frankfurt-1"
}
