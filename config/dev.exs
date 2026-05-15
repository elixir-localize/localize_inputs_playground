import Config

# Locally we still need the visualizer flag and (optionally) the
# runtime locale download. Both are off by default to keep the
# host app honest about opting in.
config :localize_inputs_playground, visualizer: true
config :localize, allow_runtime_locale_download: true
