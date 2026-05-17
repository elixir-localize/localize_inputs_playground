if Code.ensure_loaded?(Gettext.Backend) do
  defmodule Localize.Inputs.Playground.Visualizer.MoneyInputView do
    use Localize.Message.Sigils, backend: Localize.Inputs.Playground.Gettext
    @moduledoc false

    alias Money.Input.{Cast, Currency, Validator}
    alias Money.Input.Components
    alias Localize.Inputs.Playground.Visualizer.Render

    def render(params, base) do
      locale = params.locale
      default_currency = params.default_currency
      money_input = params.money_input
      picker = params.picker
      preferred = params.preferred_currencies

      money_result = parse_money_result(money_input, locale, default_currency)

      # Bogus currency from URL state — fall back to the
      # locale's natural currency rather than 500ing.
      locale_data =
        case Currency.currency_for_locale(locale, currency: default_currency) do
          {:ok, data} ->
            data

          {:error, _} ->
            case Currency.currency_for_locale(locale) do
              {:ok, data} -> data
              _ -> %{}
            end
        end

      body = [
        "<section class=\"li-card\">",
        Render.docs_link(
          "https://hexdocs.pm/ex_money_input/Money.Input.Components.html#money_input/1"
        ),
        "<h2>" <> ~t"Money Input Components" <> "</h2>",
        "<p class=\"li-desc\">",
        ~t"Live HEEx renders of <code>Money.Input.Components.money_input/1</code> and <code>Money.Input.Components.currency_picker/1</code>. For a plain number input (no currency) see the <strong>Number</strong> tab.",
        "</p>",
        "<form method=\"get\" action=\"",
        Render.escape(base),
        "/money/input\" class=\"li-form\">",
        ~s(<input type="hidden" name="submitted" value="1">),
        Render.field(
          ~t"Locale",
          Render.locale_select("locale", locale,
            reactive: true,
            always_include: [params.deployment_default_locale]
          )
        ),
        Render.field(
          ~t"Default currency",
          currency_select(default_currency),
          hint:
            ~t"Used when the form value doesn't carry a currency. Maps to the component's `:default_currency` attr."
        ),
        picker_toggle(picker),
        preferred_currencies_field(preferred),
        live_money_input_field(locale, default_currency, money_input, picker, preferred),
        "<div class=\"li-actions\">",
        "<button class=\"li-btn\" type=\"submit\">" <> ~t"Parse & format" <> "</button>",
        "<span class=\"li-hint\">",
        ~t"Try",
        " ",
        sample_hint(locale_data),
        "</span>",
        "</div>",
        "</form>",
        "</section>",
        result_card(~t"money_input result", money_result),
        code_card(locale, default_currency, picker, preferred),
        locale_card(locale_data),
        bootstrap_script(base)
      ]

      Render.page(title: "Money Input", active: {"money", "input"}, base: base, body: body)
    end

    defp live_money_input_field(locale, default_currency, value, picker, preferred) do
      form =
        make_form("money_input", value, %{
          "currency" => default_currency && to_string(default_currency)
        })

      assigns = %{
        form: form,
        field: :money_input,
        currency_field: :currency,
        locale: locale,
        default_currency: default_currency,
        __changed__: nil,
        class: nil,
        input_class: nil,
        symbol_class: nil,
        align: :right,
        min: nil,
        max: nil,
        placeholder: nil,
        js: true,
        value: nil,
        symbol_position: :auto,
        symbol_kind: :symbol,
        currency_picker: picker,
        allowed_currencies: nil,
        preferred_currencies: preferred,
        rest: %{}
      }

      rendered = Components.money_input(assigns)

      [
        "<div class=\"li-field li-field-wide\">",
        "<label>",
        "<span>" <> ~t"Money input" <> "</span>",
        Phoenix.HTML.Safe.to_iodata(rendered),
        "</label>",
        "<small class=\"li-hint\">",
        picker_hint(picker),
        "</small>",
        "</div>"
      ]
    end

    defp picker_hint(true),
      do: ~t"phx-hook=\"MoneyInput\" + embedded <code>&lt;.currency_picker&gt;</code>"

    defp picker_hint(_),
      do: ~t"phx-hook=\"MoneyInput\" — fixed currency via attr"

    defp picker_toggle(picker_on) do
      checked = if picker_on, do: " checked", else: ""

      [
        "<div class=\"li-field\">",
        "<label>",
        "<span>" <> ~t"Currency picker" <> "</span>",
        "<span>",
        ~s(<input type="checkbox" name="picker" value="1" data-li-reactive),
        checked,
        "> ",
        ~t"Embed <code>&lt;.currency_picker&gt;</code> in <code>money_input</code>",
        "</span>",
        "</label>",
        "</div>"
      ]
    end

    defp preferred_currencies_field(preferred) do
      value = Enum.map_join(preferred, ", ", &to_string/1)

      [
        "<div class=\"li-field li-field-wide\">",
        "<label>",
        "<span>",
        ~t"Preferred currencies",
        "</span>",
        ~s(<input type="text" name="preferred" data-li-reactive value="),
        Render.escape(value),
        ~s(" placeholder="USD, EUR, GBP, JPY">),
        "</label>",
        "<small class=\"li-hint\">",
        ~t"Comma-separated ISO codes — pinned to the top of the picker. Tab out or press Enter to apply.",
        "</small>",
        "</div>"
      ]
    end

    defp currency_select(current) do
      options =
        for code <- common_currencies() do
          selected = if to_string(current) == to_string(code), do: " selected", else: ""

          [
            ~s(<option value="),
            Render.escape(to_string(code)),
            ~s("),
            selected,
            ">",
            Render.escape(to_string(code)),
            "</option>"
          ]
        end

      [
        ~s(<select name="default_currency" data-li-reactive>),
        options,
        "</select>"
      ]
    end

    defp common_currencies do
      [:USD, :EUR, :GBP, :JPY, :AUD, :CAD, :CHF, :CNY, :HKD, :NZD, :SEK, :SGD, :ZAR]
    end

    defp make_form(field, value, extra) do
      params = Map.merge(extra, %{to_string(field) => value || ""})
      Phoenix.HTML.FormData.to_form(params, as: nil)
    end

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

    defp code_card(locale, default_currency, picker, preferred) do
      code = build_money_call(locale, default_currency, picker, preferred)

      [
        "<section class=\"li-card\">",
        "<h2>" <> ~t"Component code" <> "</h2>",
        "<p class=\"li-desc\">",
        ~t"The HEEx call site that renders the money_input above. Copy straight into a LiveView template.",
        "</p>",
        "<pre class=\"li-code\">",
        Render.escape(code),
        "</pre>",
        "</section>"
      ]
    end

    defp build_money_call(locale, default_currency, picker, preferred) do
      attrs =
        [
          ~s(  form={@form}),
          ~s(  field={:price}),
          ~s(  locale=#{format_locale_attr(locale)}),
          default_currency && ~s(  default_currency={:#{default_currency}}),
          picker && ~s(  currency_picker={true}),
          picker && preferred != [] &&
            ~s(  preferred_currencies={#{format_atom_list(preferred)}})
        ]
        |> Enum.reject(&is_nil/1)
        |> Enum.reject(&(&1 == false))

      "<.money_input\n" <> Enum.join(attrs, "\n") <> "\n/>"
    end

    defp format_locale_attr(locale) when is_binary(locale), do: ~s("#{locale}")
    defp format_locale_attr(locale) when is_atom(locale), do: ~s(:#{locale})

    defp format_atom_list(list) do
      inner = Enum.map_join(list, ", ", fn atom -> ":#{atom}" end)
      "[" <> inner <> "]"
    end

    defp locale_card(locale_data) do
      [
        "<section class=\"li-card\">",
        "<h2>" <> ~t"Resolved locale + currency data" <> "</h2>",
        "<p class=\"li-desc\">",
        ~t"What <code>Money.Input.Currency.currency_for_locale/2</code> returns for the current locale + currency combination — the data the JS hook reads from <code>data-</code> attributes.",
        "</p>",
        Render.code(locale_data)
      ]
    end

    defp parse_money_result(nil, _locale, _currency), do: nil
    defp parse_money_result("", _locale, _currency), do: nil
    defp parse_money_result(%{"amount" => "", "currency" => _}, _locale, _currency), do: nil

    defp parse_money_result(value, locale, currency) do
      case Cast.cast(value, locale: locale, currency: currency) do
        {:ok, nil} ->
          nil

        {:ok, %Money{} = money} ->
          canonical = Decimal.to_string(money.amount, :normal)
          formatted = Money.to_string!(money, locale: locale)
          symbol_off = Money.to_string!(money, locale: locale, currency_symbol: :none)
          validation = Validator.validate_money(money)

          [
            {~t"Submitted params", describe_money_submission(value), nil},
            {~t"Cast to Money", Money.to_string!(money) <> "  (" <> inspect(money) <> ")", nil},
            {~t"Stored amount (canonical)", canonical, nil},
            {~t"Blur format" <> " (#{locale})", formatted, nil},
            {~t"Number portion only", symbol_off, nil},
            {~t"Validation", inspect(validation), validation_css(validation)}
          ]

        {:error, reason} ->
          [
            {~t"Submitted params", describe_money_submission(value), nil},
            {~t"Error", inspect(reason), "li-bad"}
          ]
      end
    end

    defp describe_money_submission(%{} = map) do
      amount = Map.get(map, "amount") || Map.get(map, :amount) || ""
      currency = Map.get(map, "currency") || Map.get(map, :currency) || ""
      ~s(%{"amount" => "#{amount}", "currency" => "#{currency}"})
    end

    defp describe_money_submission(value), do: inspect(value)

    defp validation_css(:ok), do: nil
    defp validation_css(_), do: "li-bad"

    defp sample_hint(%{decimal: dec, group: grp}) do
      "1#{grp}234#{dec}56"
    end

    defp bootstrap_script(base) do
      [
        "<script src=\"https://cdn.jsdelivr.net/npm/autonumeric@4.10.0/dist/autoNumeric.min.js\"></script>",
        "<script type=\"module\">",
        "import MoneyHooks from \"",
        Render.escape(base),
        "/assets/money_input.js\";\n",
        "MoneyHooks.configure({ AutoNumeric: window.AutoNumeric });\n",
        "function mount(selector, hook) {\n",
        "  document.querySelectorAll(selector).forEach(el => {\n",
        "    const instance = Object.assign(Object.create(hook), { el });\n",
        "    instance.mounted();\n",
        "  });\n",
        "}\n",
        "mount('[phx-hook=\"MoneyInput\"]', MoneyHooks.MoneyInput);\n",
        "mount('[phx-hook=\"CurrencyPicker\"]', MoneyHooks.CurrencyPicker);\n",
        "document.querySelectorAll('[data-li-reactive]').forEach(el => {\n",
        "  el.addEventListener('change', () => {\n",
        "    const form = el.closest('form');\n",
        "    if (!form) return;\n",
        "    if (el.name === 'locale') {\n",
        "      const cur = form.querySelector('[name=\"default_currency\"]');\n",
        "      if (cur) cur.disabled = true;\n",
        "      form.querySelectorAll('[data-currency-picker-value]').forEach(h => h.disabled = true);\n",
        "    }\n",
        "    form.submit();\n",
        "  });\n",
        "});\n",
        "</script>"
      ]
    end
  end
end
