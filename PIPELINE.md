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
| `TF_VERSION` | `1.12.2` |
| `TF_ALLOW_EMPTY_STATE` | unset. Set `true` only when bringing up a brand-new env with no state yet |
| `TF_ROOT` | `.` |
| `TF_ENVIRONMENTS` | `dev test prod` |

**OCI credentials** (Settings → Secrets and variables → Actions). Set these once at repo level; they're shared by dev/test/prod. To use a different account for one env, add the same name on that GitHub environment, which overrides the repo value.

| Name | Kind | Purpose |
|---|---|---|
| `OCI_TENANCY_OCID` | Variable | tenancy OCID |
| `OCI_USER_OCID` | Variable | user OCID |
| `OCI_FINGERPRINT` | Variable | API key fingerprint |
| `OCI_REGION` | Variable | e.g. `eu-frankfurt-1` |
| `OCI_PRIVATE_KEY` | **Secret** | full contents of the API key `.pem` |
| `TF_STATE_PASSPHRASE` | **Secret** | *optional, not set yet*. When added, state files are stored encrypted. Keep a copy safe: without it the state can't be read |

**Per environment** (Settings → Environments → `dev` / `test` / `prod`)

| Name | Kind | Purpose |
|---|---|---|
| `TF_VAR_<NAME>` | Variable/Secret | any Terraform input `<name>` (lower-cased) |
| `TF_PLAN_ARGS` | Variable | extra plan args, e.g. `-var-file=extra.tfvars` |

## State files (stored in GitHub)

Each env's state lives on the **`tfstate`** branch of this repo:

```
tfstate branch
├── dev/terraform.tfstate
├── test/terraform.tfstate
└── prod/terraform.tfstate
```

* **plan** downloads the env's state, then plans against it.
* **apply** downloads it, applies, then commits the new state back. It does this even after a failed apply, so partial changes are recorded. Only one apply per env runs at a time.
* Every change is a commit on `tfstate`, so you get full history. To roll back, restore an older commit of that file.
* Feature-branch plans may run with an empty state if none exists yet (harmless, plan only). On `master` a missing state **fails** the run so it can never create duplicate instances.

> ⚠️ **Currently unencrypted, and this repo is public**: anyone can read the state files (IPs, OCIDs, SSH keys, any secrets in resources).
> **To turn on encryption later:** add a repository secret `TF_STATE_PASSPHRASE` (e.g. `openssl rand -base64 32`). The next apply of each env saves it as `<env>/terraform.tfstate.enc` (AES-256) and removes the plain file. No code change needed. Note that older plain copies stay in the branch history, so also delete and recreate the `tfstate` branch, or make the repo private.

## Manual approval

Each env has an `<env>-approval` GitHub environment with **Required reviewers**, restricted to the default branch. A push to `master` pauses at the approval step for every env at once. Open the run, click **Review deployments**, and tick the envs to apply (all together or one at a time). Each approved env applies in parallel.

## One-time setup

1. **Upload each env's current state** from the machine where you ran Terraform, before merging this branch:
   ```bash
   git clone https://github.com/upskillincloud-sha/oci-terraform && cd oci-terraform
   git checkout ci/terraform-pipeline
   scripts/tfstate.sh push dev  ~/instance_codes/dev/terraform.tfstate
   scripts/tfstate.sh push test ~/instance_codes/test/terraform.tfstate
   scripts/tfstate.sh push prod ~/instance_codes/prod/terraform.tfstate
   ```
   (Use the real paths of your state files.)
2. **Local runs** (optional): `scripts/tfstate.sh pull dev` gives you `dev/terraform.tfstate`. After a local apply, `scripts/tfstate.sh push dev` saves it back. Prefer applying through the pipeline so two people never apply at once.
   Credentials for local runs go in a git-ignored `local.auto.tfvars` in each env:
   ```hcl
   tenancy_ocid     = "ocid1.tenancy..."
   user_ocid        = "ocid1.user..."
   fingerprint      = "..."
   private_key_path = "~/.oci/oci_api_key.pem"
   ```
