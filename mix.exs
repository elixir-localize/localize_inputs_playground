defmodule Localize.Inputs.Playground.MixProject do
  use Mix.Project

  @version "0.1.0"
  @source_url "https://github.com/elixir-localize/localize_inputs_playground"

  def project do
    [
      app: :localize_inputs_playground,
      version: @version,
      name: "Localize.Inputs.Playground",
      source_url: @source_url,
      elixir: "~> 1.17",
      start_permanent: Mix.env() == :prod,
      deps: deps(),
      description: description(),
      docs: docs(),
      dialyzer: [
        plt_add_apps: ~w(ecto gettext mix phoenix_html phoenix_live_view plug bandit)a,
        flags: [
          :error_handling,
          :unknown,
          :underspecs,
          :extra_return,
          :missing_return
        ]
      ]
    ]
  end

  def application do
    [
      mod: {Localize.Inputs.Playground.Application, []},
      extra_applications: [:logger]
    ]
  end

  defp description do
    "Deployable host for `Localize.Inputs.Playground.Visualizer` — Bandit + a host " <>
      "router (favicon, robots.txt, /healthz) that forwards to the visualizer."
  end

  defp docs do
    [
      source_ref: "v#{@version}",
      main: "readme",
      extras: ["README.md", "CHANGELOG.md", "LICENSE.md"],
      formatters: ["html", "markdown"],
      groups_for_modules: groups_for_modules(),
      skip_code_autolink_to: [
        "Plug.Conn.t/0",
        "Supervisor.child_spec/0"
      ],
      skip_undefined_reference_warnings_on: ["CHANGELOG.md"]
    ]
  end

  defp groups_for_modules do
    [
      Host: [
        Localize.Inputs.Playground.Application,
        Localize.Inputs.Playground.Router
      ],
      Visualizer: ~r/^Localize.Inputs.Playground\.Visualizer(\.|$)/,
      Gettext: [Localize.Inputs.Playground.Gettext],
      Exceptions: [Localize.Inputs.Playground.VisualizerDisabledError]
    ]
  end

  defp deps do
    [
      {:localize, "~> 0.37"},
      {:calendrical, "~> 0.5"},
      {:localize_inputs_core, "~> 0.1"},
      {:localize_number_inputs, "~> 0.1"},
      {:localize_datetime_inputs, "~> 0.1"},
      {:ex_money_input, "~> 0.1"},
      {:localize_web, "~> 0.7"},
      {:phoenix_html, "~> 4.0"},
      {:phoenix_live_view, "~> 1.0"},
      {:gettext, "~> 1.0"},
      {:plug, "~> 1.15"},
      {:bandit, "~> 1.5"},
      {:ex_doc, "~> 0.30", only: [:dev, :release], runtime: false},
      {:dialyxir, "~> 1.4", only: :dev, runtime: false}
    ] ++ maybe_json_polyfill()
  end

  defp maybe_json_polyfill do
    if Code.ensure_loaded?(:json) do
      []
    else
      [{:json_polyfill, "~> 0.2 or ~> 1.0"}]
    end
  end
end
