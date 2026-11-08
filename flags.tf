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

# The Craving Coach's rollout and kill switch; assistant-service evaluates it locally.
resource "posthog_feature_flag" "craving_coach" {
  key                          = "craving-coach"
  name                         = "Craving Coach: rollout and kill switch (assistant-service, evaluated locally)"
  ensure_experience_continuity = false
  filters = jsonencode({
    groups = [{ properties = [], rollout_percentage = 100 }]
  })
}

# The wheel's odds: the variant names an odds profile the backoffice publishes (loyalty-service
# evaluates it locally). The weights used to be the variants' payloads; they live in the
# backoffice now, so the flag carries none. Activated when its experiment launches; once the
# experiment ships a variant, add `filters` to ignore_changes like the web app's flags.
resource "posthog_feature_flag" "spin_wheel_odds" {
  key                          = "spin-wheel-odds"
  name                         = "Spin wheel odds: the backoffice's odds profile per variant (loyalty-service, evaluated locally)"
  ensure_experience_continuity = false
  filters = jsonencode({
    groups = [{ properties = [], rollout_percentage = 100 }]
    multivariate = {
      variants = [
        { key = "control", rollout_percentage = 50 },
        { key = "generous", rollout_percentage = 50 },
      ]
    }
    # Leaving the key out keeps PostHog's old payloads; an empty map removes them.
    payloads = {}
  })

  lifecycle {
    ignore_changes = [active]
  }
}
