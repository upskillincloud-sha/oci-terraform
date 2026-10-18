# Terraform pipeline (GitHub Actions, OCI)

## What runs when

| Push to | fmt | plan (dev / test / prod) | apply |
|---|---|---|---|
| any branch except `master` | auto-fix + commit | ✅ automatic | — |
| `master` (default branch) | `fmt -check` | ✅ automatic | ⏸ manual approval per env, all envs in parallel |
| **Run workflow** button | per selected env | ✅ | only if *Also apply* is ticked (master) |

* **Environments are auto-detected**: a plan runs for each of `dev/`, `test/`, `prod/` that exists. To include `uat`, set the repo variable `TF_ENVIRONMENTS` to `dev test uat prod`. Each env also needs its own GitHub environment and approval gate.
* **Apply uses the exact plan that was reviewed** (saved from the plan job). What you approve is what gets applied.
* Plan output appears on each run's summary page.
* If you rename `master` to `main`, the pipeline follows automatically.

## Pipeline layout

```
[ fmt  dev | test | prod ] ──▶ [ plan  dev | test | prod ] ──▶ [ apply  dev | test | prod ]
      parallel                       parallel                  master only · approval · parallel
```
(A small "Detect environments" job runs first to find which env folders exist.)

## Viewing, running and rerunning

| I want to… | Do this (repo → **Actions** → **Terraform**) |
|---|---|
| See what a stage is doing | Open the run, click any box, e.g. **plan (dev)**. Logs stream live. |
| Read a plan | Open the run. Each env's plan is on the **Summary** page, and the full output is in the plan job's log. |
| Start a run by hand | **Run workflow** → pick branch, env (`all`/`dev`/`test`/`prod`), tick **Also apply** if you want apply (master only). |
| Rerun one stage | Open the run, click the job, then **⟳ Re-run this job** (or **Re-run failed jobs**). |
| Approve apply | Click **Review deployments**, tick one or more envs, then **Approve and deploy**. |
| Re-apply an env | Rerun **plan + apply** together (**Re-run all jobs**, or **Run workflow** with *Also apply*). Re-running only the apply job after state has changed fails with "saved plan is stale". That's intentional, so you never apply an outdated plan. |

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

Each env has an `<env>-approval` GitHub environment with **Required reviewers**, restricted to the default branch. A push to `master` pauses at the approval step for every env at once. Open the run, click **Review deployments**, and tick the envs to apply (all together or one at a time). Each approved env applies in parallel.

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
