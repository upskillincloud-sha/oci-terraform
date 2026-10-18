# Credentials are NOT stored here. They come from:
#   - CI: GitHub environment secrets (see PIPELINE.md)
#   - local runs: a git-ignored local.auto.tfvars file
provider "oci" {
  auth             = "APIKey"
  tenancy_ocid     = var.tenancy_ocid
  user_ocid        = var.user_ocid
  fingerprint      = var.fingerprint
  private_key_path = var.private_key_path
  region           = var.region
}
