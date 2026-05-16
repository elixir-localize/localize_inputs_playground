if Code.ensure_loaded?(Plug.Router) do
  defmodule Localize.Inputs.Playground.Visualizer do
    @moduledoc """
    A web-based visualizer for `Localize.Inputs`.

    `Plug.Router` that can be mounted inside a Phoenix or Plug
    application, or run standalone during development via
    `Localize.Inputs.Playground.Visualizer.Standalone`.

    ## Views

    * `/input` — interactive number input demo.
    * `/parse` — cross-locale parsing table.
    * `/format` — cross-locale formatting table.
    * `/locale` — locale display data table.

    ## Enable flag

    `Localize.Inputs.Playground.Visualizer.Standalone.start/1` refuses to
    boot unless `:localize_inputs_playground, :visualizer` is set to `true`
    in config (or `enabled: true` is passed explicitly).
    Mounting under `forward/2` in a Phoenix router is not gated.

    """

    use Plug.Router

    plug(Plug.Logger, log: :debug)
    plug(:match)
    plug(Plug.Parsers, parsers: [:urlencoded], pass: ["text/*"])

    # Pull the locale from the `?locale=` query param (validated)
    # and set it for `Localize.get_locale/0` and our Gettext
    # backend so every `~t"…"` lookup uses the right locale.
    plug(Localize.Plug.PutLocale,
      from: [:query, :accept_language],
      param: "locale",
      gettext: [Localize.Inputs.Playground.Gettext]
    )

    plug(:dispatch)

    alias Localize.Inputs.Playground.Visualizer.Assets
    alias Localize.Inputs.Playground.Visualizer.DateInputView
    alias Localize.Inputs.Playground.Visualizer.FormatView
    alias Localize.Inputs.Playground.Visualizer.InputView
    alias Localize.Inputs.Playground.Visualizer.LocaleView
    alias Localize.Inputs.Playground.Visualizer.ParseView
    alias Localize.Inputs.Playground.Visualizer.UnitInputView

    get "/" do
      base = base_path(conn)

      conn
      |> Plug.Conn.put_resp_header("location", base <> "/number/input")
      |> Plug.Conn.send_resp(302, "")
    end

    # ── Number section ───────────────────────────────────────

    get "/number" do
      base = base_path(conn)

      conn
      |> Plug.Conn.put_resp_header("location", base <> "/number/input")
      |> Plug.Conn.send_resp(302, "")
    end

    get "/number/input" do
      params = parse_params(conn, :input)
      html(conn, InputView.render(params, base_path(conn)))
    end

    get "/number/parse" do
      params = parse_params(conn, :parse)
      html(conn, ParseView.render(params, base_path(conn)))
    end

    get "/number/format" do
      params = parse_params(conn, :format)
      html(conn, FormatView.render(params, base_path(conn)))
    end

    get "/number/locale" do
      params = parse_params(conn, :locale)
      html(conn, LocaleView.render(params, base_path(conn)))
    end

    # ── Unit section ─────────────────────────────────────────

    get "/unit" do
      base = base_path(conn)

      conn
      |> Plug.Conn.put_resp_header("location", base <> "/unit/input")
      |> Plug.Conn.send_resp(302, "")
    end

    get "/unit/input" do
      params = parse_params(conn, :unit_input)
      html(conn, UnitInputView.render(params, base_path(conn)))
    end

    # ── Date section ─────────────────────────────────────────

    get "/date" do
      base = base_path(conn)

      conn
      |> Plug.Conn.put_resp_header("location", base <> "/date/input")
      |> Plug.Conn.send_resp(302, "")
    end

    get "/date/input" do
      params = parse_params(conn, :date_input)
      html(conn, DateInputView.render(:input, params, base_path(conn)))
    end

    get "/date/range" do
      params = parse_params(conn, :date_range)
      html(conn, DateInputView.render(:range, params, base_path(conn)))
    end

    get "/date/range-picker" do
      params = parse_params(conn, :date_range_picker)
      html(conn, DateInputView.render(:range_picker, params, base_path(conn)))
    end

    get "/date/live" do
      params = parse_params(conn, :date_live)
      html(conn, DateInputView.render(:live, params, base_path(conn)))
    end

    get "/assets/style.css" do
      conn
      |> Plug.Conn.put_resp_content_type("text/css")
      |> Plug.Conn.put_resp_header("cache-control", "public, max-age=31536000, immutable")
      |> Plug.Conn.send_resp(200, Assets.css())
    end

    get "/assets/localize_inputs.css" do
      conn
      |> Plug.Conn.put_resp_content_type("text/css")
      |> Plug.Conn.put_resp_header("cache-control", "public, max-age=31536000, immutable")
      |> Plug.Conn.send_resp(200, Assets.component_css())
    end

    get "/assets/localize_inputs.js" do
      conn
      |> Plug.Conn.put_resp_content_type("application/javascript")
      |> Plug.Conn.put_resp_header("cache-control", "public, max-age=31536000, immutable")
      |> Plug.Conn.send_resp(200, Assets.component_js())
    end

    get "/assets/logo.png" do
      conn
      |> Plug.Conn.put_resp_content_type("image/png")
      |> Plug.Conn.put_resp_header("cache-control", "public, max-age=31536000, immutable")
      |> Plug.Conn.send_resp(200, Assets.logo_png())
    end

    match _ do
      send_resp(conn, 404, "Not found")
    end

    # ---- helpers ---------------------------------------------------------

    defp html(conn, iodata) do
      conn
      |> Plug.Conn.put_resp_content_type("text/html")
      |> Plug.Conn.send_resp(200, IO.iodata_to_binary(iodata))
    end

    defp base_path(%Plug.Conn{script_name: []}), do: ""
    defp base_path(%Plug.Conn{script_name: segments}), do: "/" <> Enum.join(segments, "/")

    defp parse_params(%Plug.Conn{} = conn, view),
      do: parse_params(conn.params, view, conn.assigns)

    defp parse_params(params, :input, assigns) do
      deployment_default = default_locale(assigns)
      locale = param_locale(params, "locale", deployment_default)

      %{
        locale: locale,
        deployment_default_locale: deployment_default,
        number_input: blank_default(Map.get(params, "number_input"), nil)
      }
    end

    defp parse_params(params, :parse, _assigns) do
      %{input: blank_default(Map.get(params, "input"), "1,234.56")}
    end

    defp parse_params(params, :format, _assigns) do
      %{amount: blank_default(Map.get(params, "amount"), "1234567.89")}
    end

    defp parse_params(_params, :locale, _assigns) do
      %{}
    end

    defp parse_params(params, :unit_input, assigns) do
      deployment_default = default_locale(assigns)
      locale = param_locale(params, "locale", deployment_default)

      %{
        locale: locale,
        deployment_default_locale: deployment_default,
        category: blank_default(Map.get(params, "category"), "length"),
        unit_input: blank_default(Map.get(params, "unit_input"), nil)
      }
    end

    defp parse_params(params, :date_input, assigns) do
      deployment_default = default_locale(assigns)
      locale = param_locale(params, "locale", deployment_default)
      calendar_str = blank_default(Map.get(params, "calendar"), "gregorian")

      %{
        locale: locale,
        deployment_default_locale: deployment_default,
        calendar: validate_calendar(calendar_str),
        value: blank_default(Map.get(params, "date"), nil)
      }
    end

    defp parse_params(params, :date_range, assigns) do
      deployment_default = default_locale(assigns)
      locale = param_locale(params, "locale", deployment_default)

      %{
        locale: locale,
        deployment_default_locale: deployment_default,
        value_from: blank_default(Map.get(params, "trip_from"), nil),
        value_to: blank_default(Map.get(params, "trip_to"), nil)
      }
    end

    defp parse_params(params, :date_range_picker, assigns) do
      deployment_default = default_locale(assigns)
      locale = param_locale(params, "locale", deployment_default)
      trip = Map.get(params, "trip") || %{}

      %{
        locale: locale,
        deployment_default_locale: deployment_default,
        value_from: blank_default(Map.get(trip, "from"), nil),
        value_to: blank_default(Map.get(trip, "to"), nil)
      }
    end

    defp parse_params(_params, :date_live, assigns) do
      deployment_default = default_locale(assigns)
      %{deployment_default_locale: deployment_default}
    end

    defp validate_calendar(name) when is_binary(name) do
      atom =
        try do
          String.to_existing_atom(name)
        rescue
          _ -> :gregorian
        end

      if atom in Localize.Calendar.known_calendars(), do: atom, else: :gregorian
    end

    defp validate_calendar(_), do: :gregorian

    defp param_locale(params, key, default) do
      case Map.get(params, key) do
        nil -> default
        "" -> default
        value when is_binary(value) -> validate_locale(value) || default
      end
    end

    defp blank_default(nil, default), do: default
    defp blank_default("", default), do: default
    defp blank_default(value, _), do: value

    defp default_locale(assigns) do
      validate_locale(stringify_locale(assigns[:locale])) ||
        stringify_locale(safe_get_locale())
    end

    defp safe_get_locale do
      Localize.get_locale()
    rescue
      _ -> nil
    end

    defp stringify_locale(nil), do: nil
    defp stringify_locale(locale) when is_binary(locale), do: locale
    defp stringify_locale(locale) when is_atom(locale), do: Atom.to_string(locale)
    defp stringify_locale(%{canonical_locale_id: id}) when is_binary(id), do: id
    defp stringify_locale(_), do: nil

    defp validate_locale(nil), do: nil

    defp validate_locale(locale) do
      case Localize.validate_locale(locale) do
        {:ok, _tag} -> locale
        _ -> nil
      end
    rescue
      _ -> nil
    end
  end
end
