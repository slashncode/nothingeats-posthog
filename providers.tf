# PostHog Cloud EU. The personal API key comes from POSTHOG_API_KEY, which scripts/tofu.sh
# decrypts for the run only; it never touches a file.
provider "posthog" {
  host       = "https://eu.posthog.com"
  project_id = var.project_id
}
