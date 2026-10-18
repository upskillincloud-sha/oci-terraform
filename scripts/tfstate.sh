#!/usr/bin/env bash
# Move an environment's Terraform state to/from the encrypted "tfstate" branch.
#
#   export TF_STATE_PASSPHRASE='...same value as the GitHub secret...'
#   scripts/tfstate.sh push dev   # upload dev/terraform.tfstate  -> tfstate:dev/terraform.tfstate.enc
#   scripts/tfstate.sh pull dev   # download tfstate:dev/... -> dev/terraform.tfstate
#   scripts/tfstate.sh push dev ~/instance_codes/dev/terraform.tfstate   # upload a state file from anywhere
#
# Run from the repo root. Needs git + openssl.

set -euo pipefail
MODE="${1:?usage: $0 pull|push <env>}"
ENV_NAME="${2:?usage: $0 pull|push <env>}"
BRANCH="${TF_STATE_BRANCH:-tfstate}"
: "${TF_STATE_PASSPHRASE:?export TF_STATE_PASSPHRASE first (same value as the GitHub secret)}"
export TF_STATE_PASSPHRASE

ROOT=$(git rev-parse --show-toplevel)
STATE="${3:-$ROOT/$ENV_NAME/terraform.tfstate}"
ENC="$ENV_NAME/terraform.tfstate.enc"
crypt() { openssl enc -aes-256-cbc -pbkdf2 -iter 200000 -salt -pass env:TF_STATE_PASSPHRASE "$@"; }

git -C "$ROOT" fetch -q origin "$BRANCH"

case "$MODE" in
  pull)
    TMP=$(mktemp)
    git -C "$ROOT" show "FETCH_HEAD:$ENC" | crypt -d -out "$TMP" || { rm -f "$TMP"; echo "Decrypt failed - wrong passphrase?"; exit 1; }
    [ -f "$STATE" ] && cp "$STATE" "$STATE.before-pull"
    mv "$TMP" "$STATE"
    echo "Pulled $BRANCH:$ENC -> $STATE"
    ;;
  push)
    [ -s "$STATE" ] || { echo "No state file at $STATE"; exit 1; }
    WT=$(mktemp -d)
    trap 'git -C "$ROOT" worktree remove --force "$WT" >/dev/null 2>&1 || true' EXIT
    git -C "$ROOT" worktree add -q --detach "$WT" FETCH_HEAD
    mkdir -p "$WT/$ENV_NAME"
    crypt -in "$STATE" -out "$WT/$ENC"
    git -C "$WT" add -f "$ENC"
    git -C "$WT" commit -qm "state($ENV_NAME): uploaded manually"
    git -C "$WT" push -q origin "HEAD:refs/heads/$BRANCH"
    echo "Pushed $STATE -> $BRANCH:$ENC (encrypted)"
    ;;
  *) echo "usage: $0 pull|push <env>"; exit 1 ;;
esac
