if Code.ensure_loaded?(Gettext.Backend) do
  defmodule Localize.Inputs.Playground.Visualizer.DateInputView do
    use Localize.Message.Sigils, backend: Localize.Inputs.Playground.Gettext
    @moduledoc false

    # Pages for the date component family:
    #
    #   /date/input         — <.date_input> + JS-driven popup
    #                         calendar (Gregorian-structured, with
    #                         locale-aware labels)
    #   /date/range         — <.date_range_input> (two paired
    #                         text inputs)
    #   /date/range-picker  — <.date_range_picker> (single
    #                         shared popover, two-click range
    #                         selection)
    #   /date/live          — Documentation page for the server-
    #                         rendered `DatePickerLive` (the
    #                         playground host is plain Plug, not
    #                         a LiveView, so we can't mount the
    #                         component live here — just describe
    #                         how to use it).

    alias Localize.Inputs.Date.{Components, Parser, Validator}
    alias Localize.Inputs.Playground.Visualizer.Render

    @calendars [
      :gregorian,
      :buddhist,
      :japanese,
      :islamic_civil,
      :islamic_umalqura,
      :persian,
      :hebrew,
      :coptic,
      :ethiopic,
      :indian,
      :roc,
      :chinese,
      :dangi
    ]

    # ── /date/input ─────────────────────────────────────────

    def render(:input, params, base) do
      locale = params.locale
      calendar = params.calendar
      value = params.value

      result = parse_date_result(value, locale, calendar)

      body = [
        "<section class=\"li-card\">",
        Render.docs_link(
          "https://hexdocs.pm/localize_datetime_inputs/Localize.Inputs.Date.Components.html#date_input/1"
        ),
        "<h2>" <> ~t"Date Input Component" <> "</h2>",
        "<p class=\"li-desc\">",
        ~t"Live HEEx render of <code>Localize.Inputs.Date.Components.date_input/1</code> — a locale-aware text input paired with a popup calendar grid. The grid is structurally Gregorian; locale-correct labels (Buddhist year, Japanese imperial era, Hijri month names) flow from <code>Intl.DateTimeFormat</code> via the <code>:calendar</code> attribute. Server-side parsing accepts every CLDR pattern plus ISO-8601.",
        "</p>",
        date_form(:input, base, locale, calendar, value, params),
        "</section>",
        result_card(~t"parse_date result", result),
        code_card(:input, locale, calendar),
        date_locale_card(locale, calendar),
        bootstrap_script(base)
      ]

      Render.page(title: "Date Input", active: {"date", "input"}, base: base, body: body)
    end

    # ── /date/range ─────────────────────────────────────────

    def render(:range, params, base) do
      locale = params.locale
      calendar = params.calendar
      from = params.value_from
      to = params.value_to

      result = parse_range_pair_result(from, to, locale, calendar)

      body = [
        "<section class=\"li-card\">",
        Render.docs_link(
          "https://hexdocs.pm/localize_datetime_inputs/Localize.Inputs.Date.Components.html#date_range_input/1"
        ),
        "<h2>" <> ~t"Date Range Input Component" <> "</h2>",
        "<p class=\"li-desc\">",
        ~t"Live HEEx render of <code>Localize.Inputs.Date.Components.date_range_input/1</code> — two paired text inputs (from / to), each independently editable, with separate calendar popups. Submits as <code>params[field_from]</code> / <code>params[field_to]</code>; server-side parsing via <code>Calendrical.Date.parse_range/2</code> with the from-to tuple.",
        "</p>",
        date_form(:range, base, locale, calendar, {from, to}, params),
        "</section>",
        result_card(~t"parse_range result", result),
        code_card(:range, locale, calendar),
        date_locale_card(locale, calendar),
        bootstrap_script(base)
      ]

      Render.page(title: "Date Range", active: {"date", "range"}, base: base, body: body)
    end

    # ── /date/range-picker ─────────────────────────────────

    def render(:range_picker, params, base) do
      locale = params.locale
      calendar = params.calendar
      from = params.value_from
      to = params.value_to

      result = parse_range_pair_result(from, to, locale, calendar)

      body = [
        "<section class=\"li-card\">",
        Render.docs_link(
          "https://hexdocs.pm/localize_datetime_inputs/Localize.Inputs.Date.Components.html#date_range_picker/1"
        ),
        "<h2>" <> ~t"Date Range Picker Component" <> "</h2>",
        "<p class=\"li-desc\">",
        ~t"Live HEEx render of <code>Localize.Inputs.Date.Components.date_range_picker/1</code> — a unified date-range input with a single shared popover. Click once for the start, hover to preview the range, click again for the end. Third click on a finished range starts a new selection.",
        "</p>",
        date_form(:range_picker, base, locale, calendar, {from, to}, params),
        "</section>",
        result_card(~t"parse_range result", result),
        code_card(:range_picker, locale, calendar),
        date_locale_card(locale, calendar),
        bootstrap_script(base)
      ]

      Render.page(
        title: "Date Range Picker",
        active: {"date", "range-picker"},
        base: base,
        body: body
      )
    end

    # ── /date/live ─────────────────────────────────────────

    def render(:live, _params, base) do
      body = [
        "<section class=\"li-card\">",
        Render.docs_link(
          "https://hexdocs.pm/localize_datetime_inputs/Localize.Inputs.Date.Components.DatePickerLive.html"
        ),
        "<h2>" <> ~t"DatePickerLive — server-rendered multi-calendar grid" <> "</h2>",
        "<p class=\"li-desc\">",
        ~t"<code>Localize.Inputs.Date.Components.DatePickerLive</code> is a <code>Phoenix.LiveComponent</code>. The grid renders <strong>server-side</strong> using the configured calendar's own month structure — Hebrew leap-month boundaries, Islamic month rollovers, Persian Esfand's 29/30-day variance all behave correctly. Calendar arithmetic flows through <code>Date.add/2</code>, <code>Date.day_of_week/1</code>, and <code>Date.days_in_month/1</code> on the Calendrical Calendar behaviour module.",
        "</p>",
        "<p class=\"li-desc\">",
        ~t"This playground is a plain Plug router — it can't host a LiveView, so the component isn't mountable here. Use it inside any Phoenix LiveView like so:",
        "</p>",
        "<pre class=\"li-code\">",
        Render.escape(live_usage_snippet()),
        "</pre>",
        "</section>",
        "<section class=\"li-card\">",
        "<h2>" <> ~t"When to choose this over <.date_input>" <> "</h2>",
        "<p class=\"li-desc\">",
        ~t"For <strong>offset</strong> calendars — Buddhist, Japanese imperial, ROC — the JS-driven <code>&lt;.date_input&gt;</code> is sufficient. Their grids are Gregorian-structured (same month boundaries) and the labels shift through <code>Intl.DateTimeFormat</code>.",
        "</p>",
        "<p class=\"li-desc\">",
        ~t"For calendars with <strong>different month structure</strong> — Hebrew, Islamic, Persian, Chinese, Indian, Coptic, Ethiopic — the JS-side can't compute the correct grid (no Temporal API yet across browsers). <code>DatePickerLive</code> renders server-side via Calendrical, so the cell-to-month mapping is calendar-correct.",
        "</p>",
        "</section>"
      ]

      Render.page(title: "DatePickerLive", active: {"date", "live"}, base: base, body: body)
    end

    # ── Form rendering ──────────────────────────────────────

    defp date_form(variant, base, locale, calendar, value, params) do
      action_path =
        case variant do
          :input -> "/date/input"
          :range -> "/date/range"
          :range_picker -> "/date/range-picker"
        end

      [
        "<form method=\"get\" action=\"",
        Render.escape(base),
        action_path,
        "\" class=\"li-form\">",
        ~s(<input type="hidden" name="submitted" value="1">),
        Render.field(
          ~t"Locale",
          Render.locale_select("locale", locale,
            reactive: true,
            always_include: [params.deployment_default_locale]
          )
        ),
        Render.field(~t"Calendar", calendar_select(calendar, locale)),
        date_field(variant, value, locale, calendar),
        "<div class=\"li-actions\">",
        ~s(<button class="li-btn" type="submit">) <> ~t"Parse" <> "</button>",
        "</div>",
        "</form>"
      ]
    end

    defp calendar_select(current, locale) do
      [
        ~s(<select name="calendar" data-li-reactive>),
        Enum.map(@calendars, fn cal ->
          selected = if cal == current, do: " selected", else: ""

          [
            ~s(<option value="),
            Atom.to_string(cal),
            ~s(") <> selected <> ">",
            Render.escape(calendar_display_name(cal, locale)),
            "</option>"
          ]
        end),
        "</select>"
      ]
    end

    defp calendar_display_name(cal, locale) do
      case Localize.Calendar.display_name(:calendar, cal, locale: locale) do
        {:ok, name} -> name
        _ -> Atom.to_string(cal)
      end
    rescue
      _ -> Atom.to_string(cal)
    end

    defp date_field(:input, value, locale, calendar) do
      form = Phoenix.HTML.FormData.to_form(%{"date" => value || ""}, as: nil)

      assigns =
        base_date_input_assigns(form, :date, locale, calendar)
        |> Map.put(:rest, %{})

      rendered = Components.date_input(assigns)

      [
        "<div class=\"li-field li-field-wide\">",
        "<label><span>" <> ~t"Value" <> "</span>",
        Phoenix.HTML.Safe.to_iodata(rendered),
        "</label>",
        "<small class=\"li-hint\">" <>
          ~t"phx-hook=\"DatePicker\" — locale-formatted text + popup calendar grid" <>
          "</small>",
        "</div>"
      ]
    end

    defp date_field(:range, {from, to}, locale, calendar) do
      form =
        Phoenix.HTML.FormData.to_form(
          %{"trip_from" => from || "", "trip_to" => to || ""},
          as: nil
        )

      assigns = %{
        __changed__: nil,
        form: form,
        field: :trip,
        locale: locale,
        min: nil,
        max: nil,
        placeholder_from: nil,
        placeholder_to: nil,
        display_format: :medium,
        calendar: calendar,
        variant: :auto,
        js: true,
        class: nil,
        input_class: nil,
        button_class: nil,
        overlay_class: nil
      }

      rendered = Components.date_range_input(assigns)

      [
        "<div class=\"li-field li-field-wide\">",
        "<label><span>" <> ~t"Range" <> "</span>",
        Phoenix.HTML.Safe.to_iodata(rendered),
        "</label>",
        "<small class=\"li-hint\">" <>
          ~t"Two independent date_input children, each with its own popup." <>
          "</small>",
        "</div>"
      ]
    end

    defp date_field(:range_picker, {from, to}, locale, calendar) do
      form =
        Phoenix.HTML.FormData.to_form(
          %{"trip" => %{"from" => from || "", "to" => to || ""}},
          as: nil
        )

      assigns = %{
        __changed__: nil,
        form: form,
        field: :trip,
        locale: locale,
        min: nil,
        max: nil,
        placeholder_from: nil,
        placeholder_to: nil,
        display_format: :medium,
        calendar: calendar,
        variant: :auto,
        js: true,
        class: nil,
        input_class: nil,
        button_class: nil,
        overlay_class: nil
      }

      rendered = Components.date_range_picker(assigns)

      [
        "<div class=\"li-field li-field-wide\">",
        "<label><span>" <> ~t"Range" <> "</span>",
        Phoenix.HTML.Safe.to_iodata(rendered),
        "</label>",
        "<small class=\"li-hint\">" <>
          ~t"phx-hook=\"RangePicker\" — single popover, two-click range selection." <>
          "</small>",
        "</div>"
      ]
    end

    defp base_date_input_assigns(form, field, locale, calendar) do
      %{
        __changed__: nil,
        form: form,
        field: field,
        value: nil,
        locale: locale,
        min: nil,
        max: nil,
        placeholder: nil,
        display_format: :medium,
        calendar: calendar,
        variant: :auto,
        js: true,
        class: nil,
        input_class: nil,
        button_class: nil,
        overlay_class: nil
      }
    end

    # ── Result cards ────────────────────────────────────────

    defp parse_date_result(nil, _locale, _calendar), do: nil
    defp parse_date_result("", _locale, _calendar), do: nil

    defp parse_date_result(value, locale, calendar) when is_binary(value) do
      parsed = Parser.parse_date(value, locale: locale, calendar: calendar)
      validation = Validator.validate_date(extract_date(parsed))

      [
        {~t"Input", value, nil},
        {~t"parse_date", inspect(parsed), css_for(parsed)},
        {~t"validate_date", inspect(validation), css_for(validation)}
      ]
    end

    defp parse_range_pair_result(nil, nil, _locale, _calendar), do: nil
    defp parse_range_pair_result("", "", _locale, _calendar), do: nil

    defp parse_range_pair_result(from, to, locale, calendar) do
      from = from || ""
      to = to || ""
      # `Date.Range` is ISO-only (stdlib constraint), so
      # `parse_range/2` returns ISO endpoints. The single-date
      # parser carries the chosen calendar through natively.
      parsed = Calendrical.Date.parse_range({from, to}, locale: locale, calendar: calendar)
      validation = Validator.validate_date_range(extract_range(parsed))

      [
        {~t"From", from, nil},
        {~t"To", to, nil},
        {~t"parse_range", inspect(parsed), css_for(parsed)},
        {~t"validate_date_range", inspect(validation), css_for(validation)}
      ]
    end

    defp extract_date({:ok, %Date{} = d}), do: d
    defp extract_date(_), do: nil

    defp extract_range({:ok, %Date.Range{} = r}), do: r
    defp extract_range(_), do: nil

    defp css_for(:ok), do: nil
    defp css_for({:ok, _}), do: nil
    defp css_for(_), do: "li-bad"

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

    # ── Resolved locale + calendar data card ───────────────

    defp date_locale_card(locale, calendar) do
      data = resolve_date_locale_data(locale, calendar)

      [
        "<section class=\"li-card\">",
        "<h2>" <> ~t"Resolved locale + calendar data" <> "</h2>",
        "<p class=\"li-desc\">",
        ~t"CLDR date patterns and locale-specific metadata for the current locale + calendar — the data that drives <code>Localize.Date.to_string/2</code> and the picker grid rendering.",
        "</p>",
        Render.code(data)
      ]
    end

    defp resolve_date_locale_data(locale, calendar) do
      %{
        locale: locale,
        calendar: calendar,
        first_day_of_week: safe_first_day(locale),
        patterns: safe_date_formats(locale, calendar),
        sample: sample_formats(locale, calendar)
      }
    end

    defp safe_first_day(locale) do
      case Localize.Calendar.first_day_for_locale(locale) do
        n when is_integer(n) -> n
        _ -> nil
      end
    rescue
      _ -> nil
    end

    defp safe_date_formats(locale, calendar) do
      case Localize.DateTime.Format.date_formats(locale, calendar) do
        {:ok, formats} -> formats
        _ -> %{}
      end
    rescue
      _ -> %{}
    end

    defp sample_formats(locale, calendar) do
      today = convert_to_calendar(Date.utc_today(), calendar)

      for format <- [:short, :medium, :long, :full], into: %{} do
        formatted =
          case Localize.Date.to_string(today, locale: locale, format: format) do
            {:ok, s} -> s
            _ -> nil
          end

        {format, formatted}
      end
    rescue
      _ -> %{}
    end

    defp convert_to_calendar(date, :gregorian), do: date

    defp convert_to_calendar(date, calendar) do
      with {:ok, module} <- Calendrical.calendar_from_cldr_calendar_type(calendar),
           {:ok, converted} <- Date.convert(date, module) do
        converted
      else
        _ -> date
      end
    rescue
      _ -> date
    end

    # ── Code card ───────────────────────────────────────────

    defp code_card(variant, locale, calendar) do
      code = build_code_snippet(variant, locale, calendar)

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

    defp build_code_snippet(:input, locale, :gregorian),
      do: """
      <.date_input
        form={@form}
        field={:date}
        locale=#{format_locale_attr(locale)}
      />\
      """

    defp build_code_snippet(:input, locale, calendar),
      do: """
      <.date_input
        form={@form}
        field={:date}
        calendar=#{inspect(calendar)}
        locale=#{format_locale_attr(locale)}
      />\
      """

    defp build_code_snippet(:range, locale, :gregorian),
      do: """
      <.date_range_input
        form={@form}
        field={:trip}
        locale=#{format_locale_attr(locale)}
      />\
      """

    defp build_code_snippet(:range, locale, calendar),
      do: """
      <.date_range_input
        form={@form}
        field={:trip}
        calendar=#{inspect(calendar)}
        locale=#{format_locale_attr(locale)}
      />\
      """

    defp build_code_snippet(:range_picker, locale, calendar) when calendar == :gregorian,
      do: """
      <.date_range_picker
        form={@form}
        field={:trip}
        locale=#{format_locale_attr(locale)}
      />\
      """

    defp build_code_snippet(:range_picker, locale, calendar),
      do: """
      <.date_range_picker
        form={@form}
        field={:trip}
        calendar=#{inspect(calendar)}
        locale=#{format_locale_attr(locale)}
      />\
      """

    defp format_locale_attr(locale) when is_binary(locale), do: ~s("#{locale}")
    defp format_locale_attr(locale) when is_atom(locale), do: ~s(:#{locale})

    defp live_usage_snippet,
      do: """
      <.live_component
        module={Localize.Inputs.Date.Components.DatePickerLive}
        id="event-date"
        form={@form}
        field={:date}
        calendar={:hebrew}
        locale={:"he-IL"}
      />\
      """

    # ── bootstrap script ───────────────────────────────────

    defp bootstrap_script(base) do
      [
        "<script type=\"module\">",
        "import Hooks from \"",
        Render.escape(base),
        "/assets/localize_inputs.js\";\n",
        "function mount(selector, hook) {\n",
        "  document.querySelectorAll(selector).forEach(el => {\n",
        "    const instance = Object.assign(Object.create(hook), { el });\n",
        "    instance.mounted();\n",
        "  });\n",
        "}\n",
        "mount('[phx-hook=\"DatePicker\"]', Hooks.DatePicker);\n",
        "mount('[phx-hook=\"RangePicker\"]', Hooks.RangePicker);\n",
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
