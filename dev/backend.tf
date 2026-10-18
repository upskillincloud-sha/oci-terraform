# Remote state in OCI Object Storage. bucket/namespace/key/region are supplied at
# init time with -backend-config (CI reads them from the TF_BACKEND_CONFIG variable).
terraform {
  required_version = ">= 1.12.0"

  backend "oci" {}

  required_providers {
    oci = {
      source  = "hashicorp/oci"
      version = "~> 8.11"
    }
  }
}
