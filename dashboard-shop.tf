# "NothingEats: ordering nothing" — the shop's product dashboard, public through a share link
# (scripts/share.sh). Client events come from posthog-js after consent, server events from the
# services with the same distinct id; see nothingeats-web's TRACKING_PLAN.md.

resource "posthog_dashboard" "shop" {
  name        = "NothingEats: ordering nothing"
  description = "A fake food-ordering shop with real accounts, mails, search, events, AI and analytics: no payment, no food. Real visitors only, from consent on. Built as code in github.com/slashncode/nothingeats-posthog."
  pinned      = true
}

resource "posthog_insight" "money_not_spent" {
  name        = "Money not spent"
  description = "What every order would have cost, in euros: nothing is charged, nothing arrives."
  query_json = jsonencode({
    kind    = "DataVisualizationNode"
    display = "BoldNumber"
    source = {
      kind  = "HogQLQuery"
      query = file("${path.module}/queries/money_not_spent.sql")
    }
  })
  dashboard_ids = [posthog_dashboard.shop.id]
}

resource "posthog_insight" "calories_avoided" {
  name        = "Calories not eaten"
  description = "The calories of every dish ordered and never delivered."
  query_json = jsonencode({
    kind    = "DataVisualizationNode"
    display = "BoldNumber"
    source = {
      kind  = "HogQLQuery"
      query = file("${path.module}/queries/calories_avoided.sql")
    }
  })
  dashboard_ids = [posthog_dashboard.shop.id]
}

resource "posthog_insight" "deliveries" {
  name        = "Nothing delivered, last 30 days"
  description = "Deliveries the courier simulation finished (delivery-service)."
  query_json = jsonencode({
    kind = "InsightVizNode"
    source = {
      kind         = "TrendsQuery"
      series       = [{ kind = "EventsNode", event = "delivery_completed", math = "total", custom_name = "Deliveries" }]
      trendsFilter = { display = "BoldNumber" }
      dateRange    = { date_from = "-30d" }
    }
  })
  dashboard_ids = [posthog_dashboard.shop.id]
}

resource "posthog_insight" "order_funnel" {
  name        = "From a menu to nothing delivered"
  description = "Within a day: a menu viewed, a dish added, the checkout opened (browser), the order placed and the delivery finished (services, same person)."
  query_json = jsonencode({
    kind = "InsightVizNode"
    source = {
      kind = "FunnelsQuery"
      series = [
        {
          kind        = "EventsNode"
          event       = "$pageview"
          custom_name = "Menu viewed"
          properties  = [{ key = "$pathname", value = "/restaurants/", operator = "icontains", type = "event" }]
        },
        { kind = "EventsNode", event = "dish_add_clicked", custom_name = "Dish added" },
        { kind = "EventsNode", event = "checkout_started", custom_name = "Checkout opened" },
        { kind = "EventsNode", event = "order_placed", custom_name = "Order placed" },
        { kind = "EventsNode", event = "delivery_completed", custom_name = "Nothing delivered" },
      ]
      funnelsFilter = { funnelWindowInterval = 1, funnelWindowIntervalUnit = "day", funnelVizType = "steps" }
      dateRange     = { date_from = "-30d" }
    }
  })
  dashboard_ids = [posthog_dashboard.shop.id]
}

resource "posthog_insight" "orders" {
  name        = "Orders and customers per day"
  description = "Orders placed (ordering-service) and the people who placed them."
  query_json = jsonencode({
    kind = "InsightVizNode"
    source = {
      kind = "TrendsQuery"
      series = [
        { kind = "EventsNode", event = "order_placed", math = "total", custom_name = "Orders" },
        { kind = "EventsNode", event = "order_placed", math = "dau", custom_name = "Customers" },
      ]
      interval  = "day"
      dateRange = { date_from = "-30d" }
    }
  })
  dashboard_ids = [posthog_dashboard.shop.id]
}

resource "posthog_insight" "retention" {
  name        = "Do they order nothing again?"
  description = "Customers by the week of their first order, and the share who ordered again in each week after."
  query_json = jsonencode({
    kind = "InsightVizNode"
    source = {
      kind = "RetentionQuery"
      retentionFilter = {
        period          = "Week"
        totalIntervals  = 8
        retentionType   = "retention_first_time"
        targetEntity    = { id = "order_placed", type = "events", name = "order_placed" }
        returningEntity = { id = "order_placed", type = "events", name = "order_placed" }
      }
      dateRange = { date_from = "-8w" }
    }
  })
  dashboard_ids = [posthog_dashboard.shop.id]
}

resource "posthog_insight" "retention_by_streak" {
  name        = "Retention by streak"
  description = "The same retention, split by the daily streak a customer holds (person property loyalty_streak_days, set by loyalty-service with every delivered order): does the streak bring them back?"
  query_json = jsonencode({
    kind = "InsightVizNode"
    source = {
      kind = "RetentionQuery"
      retentionFilter = {
        period          = "Week"
        totalIntervals  = 8
        retentionType   = "retention_first_time"
        targetEntity    = { id = "order_placed", type = "events", name = "order_placed" }
        returningEntity = { id = "order_placed", type = "events", name = "order_placed" }
      }
      breakdownFilter = { breakdowns = [{ property = "loyalty_streak_days", type = "person" }] }
      dateRange       = { date_from = "-8w" }
    }
  })
  dashboard_ids = [posthog_dashboard.shop.id]
}

resource "posthog_insight" "experiment_exposures" {
  name        = "Who sees which variant"
  description = "People exposed to each experiment's variants (the browser records an exposure only while the variant is on screen; the wheel's odds are evaluated by loyalty-service)."
  query_json = jsonencode({
    kind = "InsightVizNode"
    source = {
      kind = "TrendsQuery"
      series = [{
        kind  = "EventsNode"
        event = "$feature_flag_called"
        math  = "dau"
        properties = [{
          key      = "$feature_flag"
          value    = [for flag in [posthog_feature_flag.deal_countdown, posthog_feature_flag.checkout_copy, posthog_feature_flag.coach_placement] : flag.key]
          operator = "exact"
          type     = "event"
        }]
      }]
      breakdownFilter = {
        breakdowns = [
          { property = "$feature_flag", type = "event" },
          { property = "$feature_flag_response", type = "event" },
        ]
      }
      interval     = "week"
      trendsFilter = { display = "ActionsBarValue" }
      dateRange    = { date_from = "-30d" }
    }
  })
  dashboard_ids = [posthog_dashboard.shop.id]
}

resource "posthog_insight" "searches" {
  name        = "Searches, and searches that found nothing"
  description = "search_performed (search-service) per day; zero-result searches show what the catalog is missing."
  query_json = jsonencode({
    kind = "InsightVizNode"
    source = {
      kind = "TrendsQuery"
      series = [
        { kind = "EventsNode", event = "search_performed", math = "total", custom_name = "Searches" },
        {
          kind        = "EventsNode"
          event       = "search_performed"
          math        = "total"
          custom_name = "Nothing found"
          properties  = [{ key = "results", value = "0", operator = "exact", type = "event" }]
        },
      ]
      interval  = "day"
      dateRange = { date_from = "-30d" }
    }
  })
  dashboard_ids = [posthog_dashboard.shop.id]
}

resource "posthog_insight" "zero_result_queries" {
  name          = "What people searched and did not find"
  description   = "The most frequent queries without a result in the last 30 days."
  query_sql     = file("${path.module}/queries/zero_result_queries.sql")
  dashboard_ids = [posthog_dashboard.shop.id]
}

resource "posthog_dashboard_layout" "shop" {
  dashboard_id = posthog_dashboard.shop.id
  tiles = [
    {
      # PostHog trims the body; the provider matches text tiles by their exact body.
      text_body    = trimspace(file("${path.module}/text/shop.md"))
      layouts_json = jsonencode({ sm = { x = 0, y = 0, w = 12, h = 3 } })
    },
    { insight_id = posthog_insight.money_not_spent.id, layouts_json = jsonencode({ sm = { x = 0, y = 3, w = 4, h = 4 } }) },
    { insight_id = posthog_insight.calories_avoided.id, layouts_json = jsonencode({ sm = { x = 4, y = 3, w = 4, h = 4 } }) },
    { insight_id = posthog_insight.deliveries.id, layouts_json = jsonencode({ sm = { x = 8, y = 3, w = 4, h = 4 } }) },
    { insight_id = posthog_insight.order_funnel.id, layouts_json = jsonencode({ sm = { x = 0, y = 7, w = 12, h = 6 } }) },
    { insight_id = posthog_insight.orders.id, layouts_json = jsonencode({ sm = { x = 0, y = 13, w = 6, h = 5 } }) },
    { insight_id = posthog_insight.retention.id, layouts_json = jsonencode({ sm = { x = 6, y = 13, w = 6, h = 5 } }) },
    { insight_id = posthog_insight.retention_by_streak.id, layouts_json = jsonencode({ sm = { x = 0, y = 18, w = 6, h = 5 } }) },
    { insight_id = posthog_insight.experiment_exposures.id, layouts_json = jsonencode({ sm = { x = 6, y = 18, w = 6, h = 5 } }) },
    { insight_id = posthog_insight.searches.id, layouts_json = jsonencode({ sm = { x = 0, y = 23, w = 6, h = 5 } }) },
    { insight_id = posthog_insight.zero_result_queries.id, layouts_json = jsonencode({ sm = { x = 6, y = 23, w = 6, h = 5 } }) },
  ]
}
