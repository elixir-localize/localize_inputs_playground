# Localize.Inputs.Playground

A standalone deployment wrapper for [`Localize.Inputs.Playground.Visualizer`](lib/localize/inputs/playground/visualizer.ex) — the locale-aware number input demo that previously lived in the input components library, and has never been published to hex.

The live instance runs at **<https://localize-inputs-playground.fly.dev>**.

## What it is

The input component libraries no longer ship a visualizer — moved here in 0.2 to keep them focused on the components + headless API. This package bundles:

- **`Localize.Inputs.Playground.Visualizer`** — Plug.Router with `/input`, `/parse`, `/format`, `/locale` tabs that demo the component across every CLDR locale.
- **`Localize.Inputs.Playground.Application`** — supervises a Bandit listener.
- **`Localize.Inputs.Playground.Router`** — host-level routes (robots.txt, `/healthz`) that forward everything else to the visualizer.
- **`Localize.Inputs.Playground.Gettext`** — Gettext backend with the visualizer's UI catalog. Ships translations for en, de, fr, ja, es, pt, it, zh, ar, fa, he, ru, sv, pl.
- **`Dockerfile`** + **`fly.toml`** — production deployment to Fly.io.

The input component libraries themselves are unchanged — this package depends on `localize_inputs_core`, `localize_number_inputs` and `localize_datetime_inputs` as regular hex deps.

## Local development

```bash
mix deps.get
mix run --no-halt
# Visit http://localhost:8080
```

By default the server binds to `0.0.0.0:8080`. Override either with environment variables:

```bash
PORT=4003 IP=loopback mix run --no-halt
```

## Embedding into your own Phoenix dev router

This package is not published to hex, so depend on it from git:

```elixir
# mix.exs
{:localize_inputs_playground,
 github: "elixir-localize/localize_inputs_playground", only: :dev}

# router.ex
if Mix.env() == :dev do
  forward "/inputs", Localize.Inputs.Playground.Visualizer
end

# config/dev.exs
config :localize_inputs_playground, visualizer: true
config :localize, allow_runtime_locale_download: true
```

## License

Apache-2.0. See [`LICENSE.md`](https://github.com/elixir-localize/localize_inputs_playground/blob/main/LICENSE.md).
