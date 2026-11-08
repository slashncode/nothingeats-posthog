## The Craving Coach

A chat that turns "something warm for a rainy evening" into dishes from the catalog: OpenAI's gpt-5-nano with three tools (search by meaning and keywords in Elasticsearch, look up a dish, show dish cards). Every turn is a PostHog LLM trace built from the Vercel AI SDK's lifecycle callbacks: a generation per model call, a span per tool call. PostHog prices the tokens.
