defmodule Localize.Inputs.Playground.Router do
  @moduledoc """
  Top-level router for the deployed visualizer.

  Handles a couple of host-level concerns the upstream
  `Localize.Inputs.Playground.Visualizer` library doesn't (robots.txt,
  health check) and forwards everything else to the visualizer router.

  The visualizer's gate (`config :localize_inputs_playground, visualizer: true`)
  is bypassed by setting the flag at runtime — see
  `config/runtime.exs`. The host is opting into exposing the
  dev tool publicly, which is the documented contract.

  """

  use Plug.Router

  plug(:match)
  plug(:dispatch)

  # Browsers fetch /favicon.ico unprompted. Serve the Localize
  # library's logo PNG — modern browsers accept PNG content at
  # that path and render it as the tab icon.
  get "/favicon.ico" do
    serve_logo(conn)
  end

  # iOS Safari fetches /apple-touch-icon.png (and the
  # -precomposed variant on older iOS) unprompted when a user
  # adds the page to their home screen. The source logo is
  # 1200×1200; iOS downscales to whatever it needs (typically
  # 180×180).
  get "/apple-touch-icon.png" do
    serve_logo(conn)
  end

  get "/apple-touch-icon-precomposed.png" do
    serve_logo(conn)
  end

  defp serve_logo(conn) do
    conn
    |> put_resp_content_type("image/png")
    |> put_resp_header("cache-control", "public, max-age=31536000, immutable")
    |> send_resp(200, Localize.Inputs.Playground.Visualizer.Assets.logo_png())
  end

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
  forward("/", to: Localize.Inputs.Playground.Visualizer)
end
