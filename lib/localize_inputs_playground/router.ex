defmodule LocalizeInputsPlayground.Router do
  @moduledoc """
  Top-level router for the deployed visualizer.

  Handles a couple of host-level concerns the upstream
  `LocalizeInputsPlayground.Visualizer` library doesn't (robots.txt,
  health check) and forwards everything else to the visualizer router.

  The visualizer's gate (`config :localize_inputs_playground, visualizer: true`)
  is bypassed by setting the flag at runtime — see
  `config/runtime.exs`. The host is opting into exposing the
  dev tool publicly, which is the documented contract.

  """

  use Plug.Router

  plug(:match)
  plug(:dispatch)

  # Discourage well-behaved crawlers from cataloguing every
  # possible locale permutation.
  get "/robots.txt" do
    conn
    |> put_resp_content_type("text/plain")
    |> send_resp(200, "User-agent: *\nDisallow: /\n")
  end

  # Lightweight health endpoint for fly.io's TCP/HTTP health
  # checks. Plain text, status 200, no allocation.
  get "/healthz" do
    conn
    |> put_resp_content_type("text/plain")
    |> send_resp(200, "ok")
  end

  # Everything else falls through to the visualizer.
  forward("/", to: LocalizeInputsPlayground.Visualizer)
end
