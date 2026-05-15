defmodule LocalizeInputsPlayground.Application do
  @moduledoc """
  OTP Application that runs `LocalizeInputsPlayground.Visualizer` as a
  supervised Bandit web server.

  Reads configuration from `config/runtime.exs`:

  * `PORT` environment variable (default `"8080"`).
  * `IP` environment variable: `"any"` → `{0,0,0,0}`,
    `"loopback"` → `{127,0,0,1}`. Default `"any"`.

  """

  use Application

  @impl true
  def start(_type, _args) do
    children =
      if Application.get_env(:localize_inputs_playground, :start_server, true) do
        port = Application.get_env(:localize_inputs_playground, :port, 8080)
        ip = Application.get_env(:localize_inputs_playground, :ip, {0, 0, 0, 0})

        [{Bandit, plug: LocalizeInputsPlayground.Router, port: port, ip: ip}]
      else
        []
      end

    Supervisor.start_link(children,
      strategy: :one_for_one,
      name: LocalizeInputsPlayground.Supervisor
    )
  end
end
