# Terraform state (encrypted)

This branch holds the Terraform state for each environment, one file per env:

```
dev/terraform.tfstate.enc
test/terraform.tfstate.enc
prod/terraform.tfstate.enc
```

Files are AES-256 encrypted with the `TF_STATE_PASSPHRASE` repository secret, so they are
unreadable here even though the repo is public. The pipeline reads them before plan/apply
and writes them after apply. Do not edit by hand. Use `scripts/tfstate.sh` on the main branch.
