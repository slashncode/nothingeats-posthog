# CLAUDE.md

The NothingEats PostHog project as code (OpenTofu + the `posthog/posthog` provider). The cross-repo plan and session rules live in `../CLAUDE.md` (workspace root), if present — read it first.

## Commands

Toolchain from the workspace `mise.toml` (`mise exec -- …`).

- `scripts/tofu.sh plan` / `scripts/tofu.sh apply` — the only way to run OpenTofu against PostHog: it decrypts the API key and the state passphrase from `~/.config/nothingeats/posthog-iac.sops.yaml` into the process environment.
- `tofu fmt -recursive`, and `TF_VAR_state_passphrase=validate-only-not-a-secret tofu init -backend=false && tofu validate` — what CI runs.
- `scripts/share.sh` — enables and prints the dashboards' public links.

## Rules

- Never write the API key or the passphrase to a file, a variable default, `terraform.tfvars` or a commit. `terraform.tfvars` holds only the project id.
- `terraform.tfstate` is committed and must stay encrypted (`enforced = true`); never commit `terraform.tfstate.backup` or a plan file.
- Flags the web app uses must stay locally evaluable (no experience continuity, no person-property conditions) and be listed in identity-service's `POSTHOG__CLIENT_FLAGS` (nothingeats-gitops). Their variants are typed in nothingeats-web's `src/analytics/experiments.ts`.
- Experiment lifecycle is forward-only (`draft` → `running` → `stopped`); shipping a variant needs `ignore_changes = [filters]` on the flag (already set).
- Insight names and descriptions are in English; the shop's own copy in quotes stays German.
