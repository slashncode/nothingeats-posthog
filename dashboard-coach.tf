# "NothingEats: Craving Coach" — LLM analytics of the assistant (nothingeats-assistant-service).
# Its events are built from the Vercel AI SDK's lifecycle callbacks: $ai_generation per model
# call, $ai_span per tool call, $ai_trace per turn; PostHog adds $ai_total_cost_usd from the model
# and the tokens.

resource "posthog_dashboard" "coach" {
  name        = "NothingEats: Craving Coach"
  description = "LLM analytics of the shop's AI chat: turns, cost, latency, tokens, tools, and whether a recommendation ends in the cart. Real visitors only, from consent on."
}

resource "posthog_insight" "coach_turns" {
  name        = "Coach turns and model calls per day"
  description = "A turn is one message answered ($ai_trace); it takes one model call per step ($ai_generation)."
  query_json = jsonencode({
    kind = "InsightVizNode"
    source = {
      kind = "TrendsQuery"
      series = [
        { kind = "EventsNode", event = "$ai_trace", math = "total", custom_name = "Turns" },
        { kind = "EventsNode", event = "$ai_generation", math = "total", custom_name = "Model calls" },
        { kind = "EventsNode", event = "$ai_trace", math = "dau", custom_name = "People" },
      ]
      interval  = "day"
      dateRange = { date_from = "-30d" }
    }
  })
  dashboard_ids = [posthog_dashboard.coach.id]
}

resource "posthog_insight" "coach_cost" {
  name        = "What the coach costs per day (USD)"
  description = "PostHog's price for the tokens of every model call."
  query_json = jsonencode({
    kind = "InsightVizNode"
    source = {
      kind = "TrendsQuery"
      series = [{
        kind          = "EventsNode"
        event         = "$ai_generation"
        math          = "sum"
        math_property = "$ai_total_cost_usd"
        custom_name   = "Cost (USD)"
      }]
      interval  = "day"
      dateRange = { date_from = "-30d" }
    }
  })
  dashboard_ids = [posthog_dashboard.coach.id]
}

resource "posthog_insight" "coach_latency" {
  name        = "How long a turn takes (seconds)"
  description = "From the message to the last word, including searches: median and 95th percentile."
  query_json = jsonencode({
    kind = "InsightVizNode"
    source = {
      kind = "TrendsQuery"
      series = [
        { kind = "EventsNode", event = "$ai_trace", math = "median", math_property = "$ai_latency", custom_name = "Median" },
        { kind = "EventsNode", event = "$ai_trace", math = "p95", math_property = "$ai_latency", custom_name = "95th percentile" },
      ]
      interval  = "day"
      dateRange = { date_from = "-30d" }
    }
  })
  dashboard_ids = [posthog_dashboard.coach.id]
}

resource "posthog_insight" "coach_tokens" {
  name        = "Tokens per day"
  description = "Input, output and reasoning tokens over all model calls."
  query_json = jsonencode({
    kind = "InsightVizNode"
    source = {
      kind = "TrendsQuery"
      series = [
        { kind = "EventsNode", event = "$ai_generation", math = "sum", math_property = "$ai_input_tokens", custom_name = "Input" },
        { kind = "EventsNode", event = "$ai_generation", math = "sum", math_property = "$ai_output_tokens", custom_name = "Output" },
        { kind = "EventsNode", event = "$ai_generation", math = "sum", math_property = "$ai_reasoning_tokens", custom_name = "Reasoning" },
      ]
      interval  = "day"
      dateRange = { date_from = "-30d" }
    }
  })
  dashboard_ids = [posthog_dashboard.coach.id]
}

resource "posthog_insight" "coach_tools" {
  name        = "Tool calls, and the ones that failed"
  description = "searchDishes (search-service's Retrieve over gRPC), getDish, recommendDishes (display only, checked against the catalog)."
  query_json = jsonencode({
    kind = "InsightVizNode"
    source = {
      kind = "TrendsQuery"
      series = [
        { kind = "EventsNode", event = "$ai_span", math = "total", custom_name = "Calls" },
        {
          kind        = "EventsNode"
          event       = "$ai_span"
          math        = "total"
          custom_name = "Failed"
          properties  = [{ key = "$ai_is_error", value = ["true"], operator = "exact", type = "event" }]
        },
      ]
      breakdownFilter = { breakdowns = [{ property = "$ai_span_name", type = "event" }] }
      trendsFilter    = { display = "ActionsBarValue" }
      dateRange       = { date_from = "-30d" }
    }
  })
  dashboard_ids = [posthog_dashboard.coach.id]
}

resource "posthog_insight" "coach_funnel" {
  name        = "From a craving to nothing delivered"
  description = "Within a day: a message to the coach, dish cards shown, a recommended dish added to the cart, an order placed."
  query_json = jsonencode({
    kind = "InsightVizNode"
    source = {
      kind = "FunnelsQuery"
      series = [
        { kind = "EventsNode", event = "coach_message_sent", custom_name = "Asked the coach" },
        { kind = "EventsNode", event = "coach_dishes_recommended", custom_name = "Dishes recommended" },
        {
          kind        = "EventsNode"
          event       = "dish_add_clicked"
          custom_name = "Recommended dish added"
          properties  = [{ key = "source", value = ["coach"], operator = "exact", type = "event" }]
        },
        { kind = "EventsNode", event = "order_placed", custom_name = "Order placed" },
      ]
      funnelsFilter = { funnelWindowInterval = 1, funnelWindowIntervalUnit = "day", funnelVizType = "steps" }
      dateRange     = { date_from = "-30d" }
    }
  })
  dashboard_ids = [posthog_dashboard.coach.id]
}

resource "posthog_dashboard_layout" "coach" {
  dashboard_id = posthog_dashboard.coach.id
  tiles = [
    {
      # PostHog trims the body; the provider matches text tiles by their exact body.
      text_body    = trimspace(file("${path.module}/text/coach.md"))
      layouts_json = jsonencode({ sm = { x = 0, y = 0, w = 12, h = 2 } })
    },
    { insight_id = posthog_insight.coach_turns.id, layouts_json = jsonencode({ sm = { x = 0, y = 2, w = 6, h = 5 } }) },
    { insight_id = posthog_insight.coach_cost.id, layouts_json = jsonencode({ sm = { x = 6, y = 2, w = 6, h = 5 } }) },
    { insight_id = posthog_insight.coach_latency.id, layouts_json = jsonencode({ sm = { x = 0, y = 7, w = 6, h = 5 } }) },
    { insight_id = posthog_insight.coach_tokens.id, layouts_json = jsonencode({ sm = { x = 6, y = 7, w = 6, h = 5 } }) },
    { insight_id = posthog_insight.coach_tools.id, layouts_json = jsonencode({ sm = { x = 0, y = 12, w = 6, h = 5 } }) },
    { insight_id = posthog_insight.coach_funnel.id, layouts_json = jsonencode({ sm = { x = 6, y = 12, w = 6, h = 5 } }) },
  ]
}
