#!/usr/bin/env bash
# Turns on the public share link of every dashboard this configuration manages and prints the
# links. Idempotent: an existing link stays the same. The provider has no resource for sharing.
set -euo pipefail
cd "$(dirname "$0")/.."
# Outside an activated mise shell, run again with the workspace toolchain (sops, tofu).
command -v sops >/dev/null && command -v tofu >/dev/null || exec mise exec -- "$0" "$@"

secrets="${NOTHINGEATS_POSTHOG_SECRETS:-$HOME/.config/nothingeats/posthog-iac.sops.yaml}"
key="$(sops -d --extract '["personal-api-key"]' "$secrets")"
project="$(sed -n 's/^project_id *= *"\(.*\)"/\1/p' terraform.tfvars)"
host="https://eu.posthog.com"

scripts/tofu.sh output -json dashboards | jq -r 'to_entries[] | "\(.key) \(.value)"' |
    while read -r name id; do
        token="$(curl -fsS -X PATCH "$host/api/projects/$project/dashboards/$id/sharing/" \
            -H "Authorization: Bearer $key" -H 'Content-Type: application/json' \
            -d '{"enabled": true}' | jq -r .access_token)"
        echo "$name: $host/shared/$token"
    done
