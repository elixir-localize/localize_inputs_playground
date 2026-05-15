# Changelog

## [v0.1.0] — 2026-05-16

* `Localize.Inputs.Playground.Visualizer` and related view modules — Plug-based visualizer that demos `localize_inputs`' `<.number_input>` across CLDR locales. Moved from `localize_inputs` 0.1; renamed from `Localize.Inputs.Visualizer.*` to `Localize.Inputs.Playground.Visualizer.*`.

* `Localize.Inputs.Playground.Application` + `Localize.Inputs.Playground.Router` — Bandit listener and host-level routes (robots.txt, `/healthz`) that forward everything else to the visualizer. Dockerfile + `fly.toml` for Fly.io deployment.

* `Localize.Inputs.Playground.Gettext` — Localize-interpolated Gettext backend hosting the visualizer's UI catalog. Ships with translations for en, de, fr, ja, es, pt, it, zh, ar, fa, he, ru, sv, pl.

* Locale switching via the visualizer's `?locale=…` query param is wired through `Localize.Plug.PutLocale` so both `Localize.get_locale/0` and the Gettext backend track the request locale.
