if Code.ensure_loaded?(Gettext.Backend) do
  defmodule Localize.Inputs.Playground.Visualizer.LocaleView do
    use Localize.Message.Sigils, backend: Localize.Inputs.Playground.Gettext
    @moduledoc false

    alias Localize.Inputs.Number
    alias Localize.Inputs.Playground.Visualizer.Render

    def render(_params, base) do
      rows =
        for {locale, label} <- Render.locale_options() do
          {locale, label, Number.number_for_locale(locale)}
        end

      body = [
        "<section class=\"li-card\">",
        "<h2>" <> ~t"Locale display data" <> "</h2>",
        "<p class=\"li-desc\">",
        ~t"For every demo locale, the snapshot that <code>Localize.Inputs.Number.number_for_locale/1</code> returns.",
        "</p>",
        table(rows),
        "</section>"
      ]

      Render.page(title: "Locale", active: "locale", base: base, body: body)
    end

    defp table(rows) do
      [
        "<table class=\"li-table\"><thead><tr>",
        "<th>" <>
          ~t"Locale" <>
          "</th><th>" <>
          ~t"Decimal" <>
          "</th><th>" <>
          ~t"Group" <> "</th><th>" <> ~t"Minus" <> "</th><th>" <> ~t"Digits" <> "</th>",
        "</tr></thead><tbody>",
        Enum.map(rows, &row/1),
        "</tbody></table>"
      ]
    end

    defp row({locale, label, {:ok, data}}) do
      [
        "<tr><td>",
        Render.escape(locale),
        " <small>(",
        Render.escape(label),
        ")</small></td><td class=\"li-mono\">",
        Render.escape(data.decimal),
        "</td><td class=\"li-mono\">",
        Render.escape(data.group),
        "</td><td class=\"li-mono\">",
        Render.escape(data.minus_sign),
        "</td><td class=\"li-mono\">",
        Render.escape(to_string(data.number_system)),
        "</td></tr>"
      ]
    end

    defp row({locale, label, {:error, reason}}) do
      [
        "<tr><td>",
        Render.escape(locale),
        " <small>(",
        Render.escape(label),
        ")</small></td><td colspan=\"4\" class=\"li-bad li-mono\">",
        Render.escape(inspect(reason)),
        "</td></tr>"
      ]
    end
  end
end
