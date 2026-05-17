if Code.ensure_loaded?(Gettext.Backend) do
  defmodule Localize.Inputs.Playground.Visualizer.UnitInputView do
    use Localize.Message.Sigils, backend: Localize.Inputs.Playground.Gettext
    @moduledoc false

    alias Localize.Inputs.Number.{Components, Unit, Validator}
    alias Localize.Inputs.Playground.Visualizer.Render

    def render(params, base) do
      locale = params.locale
      category = params.category
      unit_input = params.unit_input

      # Bogus category from URL state — fall back to the
      # default `"length"` rather than 500ing. If even that
      # fails (e.g. unknown locale), fall through to an
      # empty `%Unit{}` so the page renders.
      {unit_data, category} =
        case Unit.unit_for_locale(locale, category: category) do
          {:ok, data} ->
            {data, category}

          _ ->
            case Unit.unit_for_locale(locale, category: "length") do
              {:ok, data} -> {data, "length"}
              _ -> {%Unit{}, category}
            end
        end

      unit_result = parse_unit_result(unit_input, locale, category)

      body = [
        "<section class=\"li-card\">",
        Render.docs_link(
          "https://hexdocs.pm/localize_number_inputs/Localize.Inputs.Number.Components.html#unit_input/1"
        ),
        "<h2>" <> ~t"Unit Input Component" <> "</h2>",
        "<p class=\"li-desc\">",
        ~t"Live HEEx render of <code>Localize.Inputs.Number.Components.unit_input/1</code> — a locale-aware number paired with a searchable unit picker. The picker is grouped into <strong>Preferred</strong> (units in the locale's measurement system — metric, US, or UK) and <strong>All units</strong> (every known unit in the category). Unit names localize via CLDR.",
        "</p>",
        "<form method=\"get\" action=\"",
        Render.escape(base),
        "/unit/input\" class=\"li-form\">",
        ~s(<input type="hidden" name="submitted" value="1">),
        Render.field(
          ~t"Locale",
          Render.locale_select("locale", locale,
            reactive: true,
            always_include: [params.deployment_default_locale]
          )
        ),
        Render.field(~t"Category", category_select(category)),
        live_unit_input_field(category, unit_input, locale, unit_data),
        "<div class=\"li-actions\">",
        "<button class=\"li-btn\" type=\"submit\">" <> ~t"Parse & format" <> "</button>",
        "</div>",
        "</form>",
        "</section>",
        result_card(~t"unit_input result", unit_result),
        code_card(category, locale),
        unit_data_card(unit_data),
        bootstrap_script(base)
      ]

      Render.page(title: "Unit Input", active: {"unit", "input"}, base: base, body: body)
    end

    # ── form pieces ─────────────────────────────────────────

    defp category_select(current) do
      categories = Unit.known_categories() |> Enum.sort()

      [
        ~s(<select name="category" data-li-reactive>),
        Enum.map(categories, fn cat ->
          selected = if cat == current, do: " selected", else: ""

          [
            ~s(<option value="),
            Render.escape(cat),
            ~s(") <> selected <> ">",
            Render.escape(category_display_name(cat)),
            "</option>"
          ]
        end),
        "</select>"
      ]
    end

    # CLDR does not currently expose display names for unit
    # categories themselves (only for individual units within a
    # category), so we fall back to a capitalised form of the
    # category key. If a category display name API appears in
    # Localize in the future, swap the fallback for a lookup
    # here.
    defp category_display_name(category) when is_binary(category) do
      String.capitalize(category)
    end

    defp live_unit_input_field(category, value, locale, _unit_data) do
      form =
        Phoenix.HTML.FormData.to_form(%{"unit_input" => value || ""}, as: nil)

      assigns = %{
        form: form,
        field: :unit_input,
        category: category,
        default_unit: nil,
        locale: locale,
        __changed__: nil,
        value: nil,
        integer: false,
        min: nil,
        max: nil,
        decimals: nil,
        align: :left,
        placeholder: nil,
        include_prefixed: false,
        js: true,
        class: nil,
        input_class: nil,
        picker_class: nil,
        rest: %{}
      }

      rendered = Components.unit_input(assigns)

      [
        "<div class=\"li-field li-field-wide\">",
        "<label>",
        "<span>" <> ~t"Value" <> "</span>",
        Phoenix.HTML.Safe.to_iodata(rendered),
        "</label>",
        "<small class=\"li-hint\">" <>
          ~t"phx-hook=\"NumberInput\" + phx-hook=\"UnitPicker\" — locale-formatted amount, searchable picker" <>
          "</small>",
        "</div>"
      ]
    end

    # ── result + supporting cards ──────────────────────────

    defp result_card(_title, nil), do: ""

    defp result_card(title, rows) when is_list(rows) do
      rendered =
        Enum.map(rows, fn {label, value, css_class} ->
          [
            "<dt>",
            Render.escape(label),
            "</dt>",
            "<dd class=\"",
            Render.escape(css_class || ""),
            "\">",
            Render.escape(value),
            "</dd>"
          ]
        end)

      [
        "<section class=\"li-card\">",
        "<h2>",
        Render.escape(title),
        "</h2>",
        "<dl class=\"li-result\">",
        rendered,
        "</dl>",
        "</section>"
      ]
    end

    defp code_card(category, locale) do
      code = build_unit_call(category, locale)

      [
        "<section class=\"li-card\">",
        "<h2>" <> ~t"Component code" <> "</h2>",
        "<p class=\"li-desc\">",
        ~t"The HEEx call site that renders the input above. Copy straight into a LiveView template.",
        "</p>",
        "<pre class=\"li-code\">",
        Render.escape(code),
        "</pre>",
        "</section>"
      ]
    end

    defp build_unit_call(category, locale) do
      """
      <.unit_input
        form={@form}
        field={:value}
        category="#{category}"
        locale=#{format_locale_attr(locale)}
      />\
      """
    end

    defp format_locale_attr(locale) when is_binary(locale), do: ~s("#{locale}")
    defp format_locale_attr(locale) when is_atom(locale), do: ~s(:#{locale})

    defp unit_data_card(unit_data) do
      [
        "<section class=\"li-card\">",
        "<h2>" <> ~t"Resolved unit data" <> "</h2>",
        "<p class=\"li-desc\">",
        ~t"What <code>Localize.Inputs.Number.Unit.unit_for_locale/2</code> returns for the current locale + category — measurement system, preferred unit list, and the full category catalogue. Names localize via CLDR.",
        "</p>",
        Render.code(unit_data)
      ]
    end

    # ── result parsing ─────────────────────────────────────

    defp parse_unit_result(nil, _locale, _category), do: nil
    defp parse_unit_result("", _locale, _category), do: nil
    defp parse_unit_result(%{"amount" => "", "unit" => _}, _locale, _category), do: nil

    defp parse_unit_result(value, locale, category) when is_map(value) do
      amount = Map.get(value, "amount") || Map.get(value, :amount)
      unit = Map.get(value, "unit") || Map.get(value, :unit)

      case Localize.Inputs.Number.Parser.parse_number(amount, locale: locale) do
        {:ok, nil} ->
          nil

        {:ok, parsed} ->
          validation = Validator.validate_unit(value, category: category)
          unit_repr = build_unit_repr(parsed, unit)

          [
            {~t"Amount", to_string(amount), nil},
            {~t"Unit", to_string(unit), nil},
            {~t"Parsed (Decimal)", inspect(parsed), nil},
            {~t"Constructed Unit", unit_repr, nil},
            {~t"Validation", inspect(validation), validation_css(validation)}
          ]

        {:error, reason} ->
          [
            {~t"Amount", to_string(amount), nil},
            {~t"Unit", to_string(unit), nil},
            {~t"Error", inspect(reason), "li-bad"}
          ]
      end
    end

    defp parse_unit_result(_, _, _), do: nil

    # Render the effective `Localize.Unit.new(...)` call site. On
    # success we show only the call — the resulting struct is
    # uninteresting. On error we append the error tuple so the
    # user can see why construction failed.
    defp build_unit_repr(parsed, unit) when is_binary(unit) and unit != "" do
      call = "Localize.Unit.new(#{inspect(parsed)}, #{inspect(unit)})"

      case Localize.Unit.new(parsed, unit) do
        {:ok, _} -> call
        {:error, e} -> call <> "\n=> " <> inspect(e)
      end
    end

    defp build_unit_repr(_, _), do: ""

    defp validation_css(:ok), do: nil
    defp validation_css(_), do: "li-bad"

    # ── bootstrap (mirror InputView's bootstrap) ───────────

    defp bootstrap_script(base) do
      [
        "<script src=\"https://cdn.jsdelivr.net/npm/autonumeric@4.10.0/dist/autoNumeric.min.js\"></script>",
        "<script type=\"module\">",
        "import Hooks from \"",
        Render.escape(base),
        "/assets/localize_inputs.js\";\n",
        "Hooks.configure({ AutoNumeric: window.AutoNumeric });\n",
        "function mount(selector, hook) {\n",
        "  document.querySelectorAll(selector).forEach(el => {\n",
        "    const instance = Object.assign(Object.create(hook), { el });\n",
        "    instance.mounted();\n",
        "  });\n",
        "}\n",
        "mount('[phx-hook=\"NumberInput\"]', Hooks.NumberInput);\n",
        "mount('[phx-hook=\"UnitPicker\"]', Hooks.UnitPicker);\n",
        "document.querySelectorAll('[data-li-reactive]').forEach(el => {\n",
        "  el.addEventListener('change', () => {\n",
        "    const form = el.closest('form');\n",
        "    if (form) form.submit();\n",
        "  });\n",
        "});\n",
        "</script>"
      ]
    end
  end
end
