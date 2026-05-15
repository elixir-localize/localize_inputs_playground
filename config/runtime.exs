import Config

# Runtime-only switches read from the deployment environment.
# Apply in every environment so `mix run --no-halt` locally and
# `bin/localize_inputs_playground start` in production share the
# same configuration surface.

port =
  System.get_env("PORT", "8080")
  |> String.to_integer()

ip =
  case System.get_env("IP", "any") do
    "any" -> {0, 0, 0, 0}
    "loopback" -> {127, 0, 0, 1}
    _ -> {0, 0, 0, 0}
  end

config :localize_inputs_playground,
  port: port,
  ip: ip

# The visualizer ships with a safety gate
# (`config :localize_inputs_playground, visualizer: true`) so it doesn't
# accidentally end up in production. Here we *are* production
# — the playground exists to expose it — so flip it on at
# runtime regardless of environment.
config :localize_inputs_playground, visualizer: true

# Let the visualizer's locale dropdown load any CLDR locale on
# demand, not just the ones pre-compiled into the build.
config :localize, allow_runtime_locale_download: true
