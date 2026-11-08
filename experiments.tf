# Experiments on the web app's flags. The browser records the exposure ($feature_flag_called via
# posthog-js) only while the part of the page that differs is on screen, so each experiment
# counts the people who saw it. Metrics are funnels from that exposure; server events
# (order_placed) carry the same distinct id as the browser.
#
# Traffic is real visitors only: no simulated crowd. With a fake shop's traffic these run for a
# long time before they say anything, and that is part of the story.

resource "posthog_experiment" "deal_countdown" {
  name             = "Deal countdown: ticking clock or end time"
  description      = "Does a ticking clock on flash deals (\"noch 12:34\") make people add more deal dishes than the time the deal ends (\"bis 23:59 Uhr\")? Urgency without fake stock: the clock is the only pressure the shop applies."
  feature_flag_key = posthog_feature_flag.deal_countdown.key

  metrics = jsonencode([
    {
      kind        = "ExperimentMetric"
      metric_type = "funnel"
      name        = "Added a deal dish"
      series = [{
        kind       = "EventsNode"
        event      = "dish_add_clicked"
        properties = [{ key = "on_deal", value = ["true"], operator = "exact", type = "event" }]
      }]
    }
  ])

  metrics_secondary = jsonencode([
    {
      kind        = "ExperimentMetric"
      metric_type = "funnel"
      name        = "Placed an order"
      series      = [{ kind = "EventsNode", event = "order_placed" }]
    }
  ])

  # Leaves out the project's test accounts (Settings → test account filters).
  exposure_criteria = jsonencode({ filterTestAccounts = true })

  status {
    state = "running"
  }
}

resource "posthog_experiment" "checkout_copy" {
  name             = "Checkout copy: the joke or the plain button"
  description      = "Does \"Mit Willenskraft bezahlen\" (and \"Es wird nichts abgebucht. Es kommt nur nichts.\") lose orders against a plain \"Jetzt bestellen\" (\"Kostenlos. Es kommt nichts.\")? Shown to everyone who reaches the checkout with a cart."
  feature_flag_key = posthog_feature_flag.checkout_copy.key

  metrics = jsonencode([
    {
      kind        = "ExperimentMetric"
      metric_type = "funnel"
      name        = "Placed an order"
      series      = [{ kind = "EventsNode", event = "order_placed" }]
    }
  ])

  # Leaves out the project's test accounts (Settings → test account filters).
  exposure_criteria = jsonencode({ filterTestAccounts = true })

  status {
    state = "running"
  }
}

resource "posthog_experiment" "coach_placement" {
  name             = "Coach placement: corner button or invitation on menus"
  description      = "Do more people talk to the Craving Coach when a menu invites them (\"Unentschlossen?\") than with the button in the corner alone? Counts visitors who saw a menu while the coach was offered."
  feature_flag_key = posthog_feature_flag.coach_placement.key

  metrics = jsonencode([
    {
      kind        = "ExperimentMetric"
      metric_type = "funnel"
      name        = "Sent the coach a message"
      series      = [{ kind = "EventsNode", event = "coach_message_sent" }]
    }
  ])

  metrics_secondary = jsonencode([
    {
      kind        = "ExperimentMetric"
      metric_type = "funnel"
      name        = "Opened the coach"
      series      = [{ kind = "EventsNode", event = "coach_opened" }]
    },
    {
      kind        = "ExperimentMetric"
      metric_type = "funnel"
      name        = "Added a dish the coach recommended"
      series = [{
        kind       = "EventsNode"
        event      = "dish_add_clicked"
        properties = [{ key = "source", value = ["coach"], operator = "exact", type = "event" }]
      }]
    }
  ])

  # Leaves out the project's test accounts (Settings → test account filters).
  exposure_criteria = jsonencode({ filterTestAccounts = true })

  status {
    state = "running"
  }
}

# Phase 4's experiment, built in the UI and never launched: its only metric counted $pageview
# under the name order_placed. Kept a draft until it is launched on purpose.
resource "posthog_experiment" "spin_wheel_odds" {
  name             = "Spin wheel odds"
  description      = "Do generous odds on the level-up wheel (more free dishes and 20 % coupons, fewer bonus XP) bring customers back to order more nothing? The variant names an odds profile in the backoffice; loyalty-service evaluates the flag at every spin."
  feature_flag_key = posthog_feature_flag.spin_wheel_odds.key

  metrics = jsonencode([
    {
      kind        = "ExperimentMetric"
      metric_type = "funnel"
      name        = "Placed an order"
      series      = [{ kind = "EventsNode", event = "order_placed" }]
    }
  ])

  metrics_secondary = jsonencode([
    {
      kind        = "ExperimentMetric"
      metric_type = "funnel"
      name        = "Redeemed a coupon"
      series      = [{ kind = "EventsNode", event = "coupon_applied" }]
    }
  ])

  # Leaves out the project's test accounts (Settings → test account filters).
  exposure_criteria = jsonencode({ filterTestAccounts = true })

  status {
    state = "draft"
  }
}
