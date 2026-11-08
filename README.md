# nothingeats-posthog

The [NothingEats](https://github.com/slashncode/nothingeats) project in PostHog, as code: feature flags, experiments and dashboards, managed with OpenTofu and [PostHog's own provider](https://github.com/PostHog/terraform-provider-posthog). NothingEats is a fake food-ordering shop with real accounts, mails, search, events and an AI coach: no payment, no food. PostHog is its analytics, flags, experiments, replay, surveys, error tracking, logs and LLM analytics backbone.

## What is in here

| File | What |
|---|---|
| `flags.tf` | The web app's experiment flags: `deal-countdown`, `checkout-copy`, `coach-placement` |
| `experiments.tf` | One experiment per flag, with its metrics |
| `dashboard-shop.tf` | "NothingEats: ordering nothing": money not spent, the funnel from a menu to nothing delivered, orders, retention (also by streak), who sees which variant, searches that found nothing |
| `dashboard-coach.tf` | "NothingEats: Craving Coach": LLM analytics of the AI chat (turns, cost, latency, tokens, tool calls, recommendation to order) |
| `queries/`, `text/` | SQL (HogQL) of the SQL insights, markdown of the text tiles |

## Experiments

| Flag | Control | Other arm | Primary metric |
|---|---|---|---|
| `deal-countdown` | Flash deals tick ("noch 12:34") | The time they end ("bis 23:59 Uhr") | Added a deal dish |
| `checkout-copy` | "Mit Willenskraft bezahlen" | "Jetzt bestellen" | Placed an order |
| `coach-placement` | The coach in the corner | Also invited above every menu | Sent the coach a message |

The flags split on the distinct id alone, so identity-service evaluates them locally with the project's Feature Flags Secure API Key and hands them to the browser before its first render: the variant shows from the first paint, without a flicker (nothingeats-web's `TRACKING_PLAN.md`). The browser records the exposure only while the part of the page that differs is on screen. Visitors who did not agree to analytics have no flags and see control.

The traffic is real visitors only, no simulated crowd: a fake shop's experiments take a long time to say anything.

## Running it

Locally, by the owner:

```sh
scripts/tofu.sh plan
scripts/tofu.sh apply
scripts/share.sh        # public links of the dashboards
```

- `scripts/tofu.sh` decrypts a personal API key (scopes `dashboard`, `insight`, `feature_flag`, `experiment`, `survey`, `sharing_configuration` write, `project` read) and the state passphrase from a SOPS file outside the repository, into the environment of that one process.
- The state is committed, encrypted with OpenTofu's state encryption (AES-GCM, key from the passphrase). Plans are encrypted too.
- CI checks formatting and validates the configuration; it has no key and never talks to PostHog.
- Everything here is changed here, not in the PostHog UI: a change made in the UI shows up as drift on the next plan.

## License

MIT
