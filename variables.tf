variable "project_id" {
  description = "The NothingEats project in PostHog (EU)."
  type        = string
}

variable "state_passphrase" {
  description = "Encrypts the state and saved plans; from the owner's SOPS file via scripts/tofu.sh."
  type        = string
  sensitive   = true
}
