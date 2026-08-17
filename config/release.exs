import Config

# The `:release` environment exists solely to build documentation
# (`MIX_ENV=release mix docs`), which runs in its own env so that
# dev-only modules don't leak into the output. Nothing is started
# here — the settings below only need to be present so the
# compile that precedes the docs build succeeds.
config :localize_inputs_playground, visualizer: true
config :localize, allow_runtime_locale_download: true
