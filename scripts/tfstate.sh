#!/usr/bin/env bash
# Move an environment's Terraform state to/from the "tfstate" branch.
# Plain <env>/terraform.tfstate by default. If TF_STATE_PASSPHRASE is exported (same value
# as the GitHub secret), it is stored encrypted as <env>/terraform.tfstate.enc instead.
#
#   scripts/tfstate.sh push dev   # upload dev/terraform.tfstate  -> tfstate:dev/terraform.tfstate
#   scripts/tfstate.sh pull dev   # download tfstate:dev/... -> dev/terraform.tfstate
#   scripts/tfstate.sh push dev ~/instance_codes/dev/terraform.tfstate   # upload a state file from anywhere
#
# Run from the repo root. Needs git + openssl.

set -euo pipefail
MODE="${1:?usage: $0 pull|push <env>}"
ENV_NAME="${2:?usage: $0 pull|push <env>}"
BRANCH="${TF_STATE_BRANCH:-tfstate}"
export TF_STATE_PASSPHRASE="${TF_STATE_PASSPHRASE:-}"

ROOT=$(git rev-parse --show-toplevel)
STATE="${3:-$ROOT/$ENV_NAME/terraform.tfstate}"
ENC="$ENV_NAME/terraform.tfstate.enc"
PLAIN="$ENV_NAME/terraform.tfstate"
crypt() { openssl enc -aes-256-cbc -pbkdf2 -iter 200000 -salt -pass env:TF_STATE_PASSPHRASE "$@"; }

git -C "$ROOT" fetch -q origin "$BRANCH"

case "$MODE" in
  pull)
    TMP=$(mktemp)
    if git -C "$ROOT" cat-file -e "FETCH_HEAD:$ENC" 2>/dev/null; then
      [ -n "$TF_STATE_PASSPHRASE" ] || { echo "State is encrypted - export TF_STATE_PASSPHRASE"; exit 1; }
      git -C "$ROOT" show "FETCH_HEAD:$ENC" | crypt -d -out "$TMP" || { rm -f "$TMP"; echo "Decrypt failed - wrong passphrase?"; exit 1; }
    else
      git -C "$ROOT" show "FETCH_HEAD:$PLAIN" > "$TMP" || { rm -f "$TMP"; echo "No state for $ENV_NAME on $BRANCH"; exit 1; }
    fi
    [ -f "$STATE" ] && cp "$STATE" "$STATE.before-pull"
    mv "$TMP" "$STATE"
    echo "Pulled $ENV_NAME state from $BRANCH -> $STATE"
    ;;
  push)
    [ -s "$STATE" ] || { echo "No state file at $STATE"; exit 1; }
    WT=$(mktemp -d)
    trap 'git -C "$ROOT" worktree remove --force "$WT" >/dev/null 2>&1 || true' EXIT
    git -C "$ROOT" worktree add -q --detach "$WT" FETCH_HEAD
    mkdir -p "$WT/$ENV_NAME"
    if [ -n "$TF_STATE_PASSPHRASE" ]; then
      crypt -in "$STATE" -out "$WT/$ENC"; SAVED="$ENC"; git -C "$WT" rm -q --ignore-unmatch "$PLAIN"
    else
      cp "$STATE" "$WT/$PLAIN"; SAVED="$PLAIN"; git -C "$WT" rm -q --ignore-unmatch "$ENC"
    fi
    git -C "$WT" add -f "$SAVED"
    git -C "$WT" commit -qm "state($ENV_NAME): uploaded manually"
    git -C "$WT" push -q origin "HEAD:refs/heads/$BRANCH"
    echo "Pushed $STATE -> $BRANCH:$SAVED"
    ;;
  *) echo "usage: $0 pull|push <env>"; exit 1 ;;
esac
