#!/usr/bin/env bash
# Runs OpenTofu with the PostHog personal API key and the state passphrase from the owner's SOPS
# file, in the environment of this one process only: neither ever touches a file in plain text.
set -euo pipefail
cd "$(dirname "$0")/.."
# Outside an activated mise shell, run again with the workspace toolchain (sops, tofu).
command -v sops >/dev/null && command -v tofu >/dev/null || exec mise exec -- "$0" "$@"

secrets="${NOTHINGEATS_POSTHOG_SECRETS:-$HOME/.config/nothingeats/posthog-iac.sops.yaml}"
POSTHOG_API_KEY="$(sops -d --extract '["personal-api-key"]' "$secrets")"
TF_VAR_state_passphrase="$(sops -d --extract '["state-passphrase"]' "$secrets")"
export POSTHOG_API_KEY TF_VAR_state_passphrase

exec tofu "$@"
