# Terraform pipeline (GitHub Actions, OCI)

## What runs when

| Push to | fmt | plan (dev / test / prod) | apply |
|---|---|---|---|
| any branch except `master` | auto-fix + commit | ✅ automatic | — |
| `master` (default branch) | `fmt -check` | ✅ automatic | ⏸ manual approval per env, dev → test → prod |

* **Environments are auto-detected**: a plan runs for each of `dev/`, `test/`, `prod/` that exists. To include `uat`, set the repo variable `TF_ENVIRONMENTS` to `dev test uat prod`. Each env also needs its own GitHub environment and approval gate.
* **Apply uses the exact plan that was reviewed** (saved from the plan job). What you approve is what gets applied.
* Plan output appears on each run's summary page.
* If you rename `master` to `main`, the pipeline follows automatically.

## Where config lives (nothing hard-coded in the repo)

**Repo variables** (Settings → Secrets and variables → Actions)

| Name | Value |
|---|---|
| `TF_VERSION` | `1.12.2` (≥ 1.12 needed for the OCI state backend) |
| `TF_ROOT` | `.` |
| `TF_ENVIRONMENTS` | `dev test prod` |

**Per environment** (Settings → Environments → `dev` / `test` / `prod`)

| Name | Kind | Purpose |
|---|---|---|
| `OCI_TENANCY_OCID`, `OCI_USER_OCID`, `OCI_FINGERPRINT` | Secret | API-key auth |
| `OCI_PRIVATE_KEY` | Secret | full contents of the API key `.pem` |
| `OCI_REGION` | Variable | e.g. `eu-frankfurt-1` |
| `TF_BACKEND_CONFIG` | Variable | state location: `bucket`, `namespace`, `key`, `region` lines |
| `TF_VAR_<NAME>` | Variable/Secret | any Terraform input `<name>` (lower-cased) |
| `TF_PLAN_ARGS` | Variable | extra plan args, e.g. `-var-file=extra.tfvars` |

## Manual approval

Each env has an `<env>-approval` GitHub environment with **Required reviewers**, restricted to the default branch. A push to `master` pauses at "Approve dev". Open the run, click **Review deployments → Approve**, and the next env waits in turn.

## One-time setup

1. **Create a state bucket** in OCI Object Storage, e.g. `tfstate`. Note your namespace (`oci os ns get`).
2. **Move each env's existing state into it** from your machine, before merging this branch. Run this inside `dev/`, `test/` and `prod/`:
   ```bash
   cat > backend.hcl <<EOF
   bucket    = "tfstate"
   namespace = "<namespace>"
   key       = "dev/terraform.tfstate"   # change per env
   region    = "eu-frankfurt-1"
   EOF
   terraform init -migrate-state -backend-config=backend.hcl
   ```
3. **Local runs:** create a git-ignored `local.auto.tfvars` in each env:
   ```hcl
   tenancy_ocid     = "ocid1.tenancy..."
   user_ocid        = "ocid1.user..."
   fingerprint      = "..."
   private_key_path = "~/.oci/oci_api_key.pem"
   ```
4. **GitHub side:** edit the CONFIG block in the script, then run
   ```bash
   ./scripts/setup-github-envs.sh upskillincloud-sha/oci-terraform <your-github-username> ~/.oci/oci_api_key.pem
   ```
