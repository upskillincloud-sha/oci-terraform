# State: no backend block, so Terraform uses a local terraform.tfstate.
# In CI the pipeline downloads this env's encrypted state from the "tfstate" branch
# before plan/apply and saves it back after apply (see PIPELINE.md).
# Locally: scripts/tfstate.sh pull|push <env>
terraform {
  required_version = ">= 1.5.0"

  required_providers {
    oci = {
      source  = "hashicorp/oci"
      version = "~> 8.11"
    }
  }
}
