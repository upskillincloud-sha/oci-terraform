#!/usr/bin/env bash
# One-time GitHub setup for the Terraform pipeline (OCI).
# Needs the GitHub CLI (gh) logged in with admin rights on the repo.
#
#   ./scripts/setup-github-envs.sh <owner/repo> <approver-github-username> <path-to-NEW-oci-api-key.pem>
#
# Creates, for each of dev/test/prod:
#   <env>           - holds that env's config Variables & Secrets (used by plan and apply)
#   <env>-approval  - required reviewer = approver, only the default branch can deploy -> manual apply gate
# Edit the CONFIG block before running.

set -euo pipefail
REPO="${1:?usage: $0 <owner/repo> <approver-username> <oci-api-key.pem>}"
APPROVER="${2:?usage: $0 <owner/repo> <approver-username> <oci-api-key.pem>}"
KEY_FILE="${3:?usage: $0 <owner/repo> <approver-username> <oci-api-key.pem>}"
ENVS=(dev test prod)

# ------------------------------------------------------------------ CONFIG
OCI_TENANCY_OCID="ocid1.tenancy.oc1..CHANGE_ME"
OCI_USER_OCID="ocid1.user.oc1..CHANGE_ME"
OCI_FINGERPRINT="aa:bb:cc:CHANGE_ME"        # fingerprint of the NEW key
OCI_REGION="eu-frankfurt-1"
STATE_BUCKET="tfstate"                       # Object Storage bucket for state
STATE_NAMESPACE="CHANGE_ME"                  # oci os ns get
# --------------------------------------------------------------------------

APPROVER_ID=$(gh api "users/$APPROVER" --jq .id)
DEFAULT_BRANCH=$(gh api "repos/$REPO" --jq .default_branch)

gh variable set TF_VERSION      --repo "$REPO" --body "1.12.2"
gh variable set TF_ROOT         --repo "$REPO" --body "."
gh variable set TF_ENVIRONMENTS --repo "$REPO" --body "dev test prod"

for env in "${ENVS[@]}"; do
  echo "==> $env"
  gh api -X PUT "repos/$REPO/environments/$env" --silent

  gh api -X PUT "repos/$REPO/environments/$env-approval" --silent --input - <<JSON
{
  "reviewers": [{ "type": "User", "id": $APPROVER_ID }],
  "deployment_branch_policy": { "protected_branches": false, "custom_branch_policies": true }
}
JSON
  gh api -X POST "repos/$REPO/environments/$env-approval/deployment-branch-policies" \
    -f name="$DEFAULT_BRANCH" -f type=branch --silent 2>/dev/null || true

  # non-secret config
  gh variable set OCI_REGION        --repo "$REPO" --env "$env" --body "$OCI_REGION"
  gh variable set TF_BACKEND_CONFIG --repo "$REPO" --env "$env" --body "bucket    = \"$STATE_BUCKET\"
namespace = \"$STATE_NAMESPACE\"
key       = \"$env/terraform.tfstate\"
region    = \"$OCI_REGION\""

  # credentials
  gh secret set OCI_TENANCY_OCID --repo "$REPO" --env "$env" --body "$OCI_TENANCY_OCID"
  gh secret set OCI_USER_OCID    --repo "$REPO" --env "$env" --body "$OCI_USER_OCID"
  gh secret set OCI_FINGERPRINT  --repo "$REPO" --env "$env" --body "$OCI_FINGERPRINT"
  gh secret set OCI_PRIVATE_KEY  --repo "$REPO" --env "$env" < "$KEY_FILE"
done

echo "Done. Check Settings -> Environments in $REPO."
