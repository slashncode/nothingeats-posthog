# Feature flags. The web app's experiment flags are evaluated by identity-service with the
# project's Feature Flags Secure API Key (local evaluation) and served to the browser before its
# first render (GET /api/identity/v1/flags; the list is POSTHOG__CLIENT_FLAGS in
# nothingeats-gitops). Local evaluation rules out experience continuity and conditions on person
# properties the service does not know, so these flags split on the distinct id alone.
#
# `ignore_changes = [filters]`: once an experiment ships its winner, PostHog rewrites the flag's
# split; the flag must not fight it on the next apply.

locals {
  # 50/50 between control and one other arm, for everyone.
  two_arms = {
    for flag, other in {
      deal_countdown  = { key = "until", name = "End time" }
      checkout_copy   = { key = "plain", name = "Plain" }
      coach_placement = { key = "menu", name = "Invitation on menus" }
      } : flag => {
      groups = [{ properties = [], rollout_percentage = 100 }]
      multivariate = {
        variants = [
          { key = "control", name = "Control", rollout_percentage = 50 },
          { key = other.key, name = other.name, rollout_percentage = 50 },
        ]
      }
    }
  }
}

resource "posthog_feature_flag" "deal_countdown" {
  key                          = "deal-countdown"
  name                         = "Web experiment: flash deals show a ticking clock (control) or the time they end (until)"
  ensure_experience_continuity = false
  filters                      = jsonencode(local.two_arms.deal_countdown)

  lifecycle {
    ignore_changes = [filters]
  }
}

resource "posthog_feature_flag" "checkout_copy" {
  key                          = "checkout-copy"
  name                         = "Web experiment: the checkout button says \"Mit Willenskraft bezahlen\" (control) or \"Jetzt bestellen\" (plain)"
  ensure_experience_continuity = false
  filters                      = jsonencode(local.two_arms.checkout_copy)

  lifecycle {
    ignore_changes = [filters]
  }
}

resource "posthog_feature_flag" "coach_placement" {
  key                          = "coach-placement"
  name                         = "Web experiment: the Craving Coach only in the corner (control) or also invited above every menu (menu)"
  ensure_experience_continuity = false
  filters                      = jsonencode(local.two_arms.coach_placement)

  lifecycle {
    ignore_changes = [filters]
  }
}
