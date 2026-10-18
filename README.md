# Terraform state

This branch holds the Terraform state for each environment, one file per env:

```
dev/terraform.tfstate
test/terraform.tfstate
prod/terraform.tfstate
```

The pipeline reads them before plan/apply and writes them after apply. Do not edit by hand.
Use `scripts/tfstate.sh` on the main branch.

If the `TF_STATE_PASSPHRASE` secret is set, files are stored AES-256 encrypted as
`<env>/terraform.tfstate.enc` instead.
