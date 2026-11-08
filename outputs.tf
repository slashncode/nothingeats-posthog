output "dashboards" {
  description = "Dashboard ids by name, for scripts/share.sh."
  value = {
    shop  = posthog_dashboard.shop.id
    coach = posthog_dashboard.coach.id
  }
}
