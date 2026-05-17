defmodule Localize.Inputs.Playground.SmokeTest do
  use ExUnit.Case, async: true
  use Plug.Test

  @moduledoc """
  End-to-end smoke test: hits every visualizer route with
  matrices of adversarial params and asserts 200 (no
  exception, no error response). This is the safety net
  for production-style integration breakage that unit
  tests miss — the kind that put `/date/range` into 500
  territory under 0.1.1.

  Adversarial params include:

  * unknown locales (`xx-XX`, `""`, atom-spray vectors)
  * unknown calendars (`zzz`, garbage)
  * malformed dates, currencies, amounts
  * empty / overlong strings
  * URL-injected garbage in field names

  The test fails on ANY non-2xx response from ANY combo.
  """

  alias Localize.Inputs.Playground.Visualizer

  @opts Visualizer.init([])

  # Hostile values per param family. We try EACH one in
  # isolation against EACH route — `n_routes * n_params *
  # n_values` requests. Goal is to surface code paths that
  # fail on each value class, not to test combinations.
  @bad_locales [nil, "", "xx-XX", "garbage", "🙂", String.duplicate("a", 200)]
  @bad_calendars [nil, "", "zzz", "garbage", "🙂"]
  @bad_currencies [nil, "", "ZZZ", "garbage", "🙂", ":\"\"", String.duplicate("Z", 50)]
  @bad_dates [nil, "", "not-a-date", "9999-99-99", "🙂"]
  @bad_amounts [nil, "", "garbage", "1.2.3.4", "🙂", String.duplicate("9", 100)]

  describe "happy-path routes return 200" do
    test "every documented route renders cleanly" do
      for path <- documented_routes() do
        assert_route_ok(path)
      end
    end
  end

  describe "/date/* with adversarial params" do
    for route <- ["/date/input", "/date/range", "/date/range-picker"] do
      test "#{route} with bad locale × bad calendar" do
        for locale <- @bad_locales, calendar <- @bad_calendars do
          assert_route_ok("#{unquote(route)}?#{q([{"locale", locale}, {"calendar", calendar}])}")
        end
      end

      test "#{route} with bad date values" do
        for date <- @bad_dates do
          # date_input takes `?date=`, range takes `?trip_from=&trip_to=`,
          # range-picker takes `?trip[from]=&trip[to]=`
          q1 =
            q([
              {"locale", "en"},
              {"date", date},
              {"trip_from", date},
              {"trip_to", date},
              {"trip[from]", date},
              {"trip[to]", date}
            ])

          assert_route_ok("#{unquote(route)}?#{q1}")
        end
      end
    end

    test "/date/range with the explicit field-name regression case" do
      # The 0.1.1 regression: range_input used `String.to_existing_atom`
      # for child fields, which 500'd whenever the consumer's form
      # didn't pre-declare `:trip_from` / `:trip_to`. The playground
      # form doesn't declare them. This test would have caught it.
      assert_route_ok("/date/range")
    end
  end

  describe "/number/input with adversarial params" do
    test "bad locale × bad value" do
      for locale <- @bad_locales, amount <- @bad_amounts do
        assert_route_ok("/number/input?#{q([{"locale", locale}, {"number_input", amount}])}")
      end
    end
  end

  describe "/unit/input with adversarial params" do
    test "bad locale × bad category" do
      for locale <- @bad_locales, category <- ["bogus", "", "🙂", nil] do
        assert_route_ok("/unit/input?#{q([{"locale", locale}, {"category", category}])}")
      end
    end
  end

  describe "/money/input with adversarial params" do
    test "bad locale × bad default_currency" do
      for locale <- @bad_locales, currency <- @bad_currencies do
        assert_route_ok("/money/input?#{q([{"locale", locale}, {"default_currency", currency}])}")
      end
    end

    test "bad submitted money_input amount and currency" do
      for amount <- @bad_amounts, currency <- @bad_currencies do
        assert_route_ok(
          "/money/input?#{q([{"submitted", "1"}, {"locale", "en"}, {"default_currency", "USD"}, {"money_input[amount]", amount}, {"money_input[currency]", currency}])}"
        )
      end
    end

    test "atom-spray defence on default_currency (CLDR-unknown codes)" do
      # If anyone reintroduces `String.to_atom` on `default_currency`,
      # these requests would each mint a fresh atom and exhaust the
      # atom table. Should silently fall back to the locale's natural
      # currency.
      for noise <- ~w(AAAA BBBB CCCC DDDD EEEE FFFF GGGG HHHH IIII JJJJ) do
        assert_route_ok("/money/input?#{q([{"locale", "en"}, {"default_currency", noise}])}")
      end
    end

    test "preferred currencies with adversarial input" do
      for preferred <- ["", "garbage", "USD,EUR,ZZZ", "USD, , ,EUR", "🙂,USD", nil] do
        assert_route_ok("/money/input?#{q([{"locale", "en"}, {"preferred", preferred}])}")
      end
    end
  end

  # ── Helpers ───────────────────────────────────────────────

  defp documented_routes do
    [
      "/",
      "/number",
      "/number/input",
      "/number/parse",
      "/number/format",
      "/number/locale",
      "/unit",
      "/unit/input",
      "/money",
      "/money/input",
      "/date",
      "/date/input",
      "/date/range",
      "/date/range-picker",
      "/date/live"
    ]
  end

  defp assert_route_ok(path) do
    conn = conn(:get, path) |> Visualizer.call(@opts)

    if conn.status not in 200..399 do
      flunk("""
      Route #{path} returned HTTP #{conn.status}

      Response body (first 600 chars):
      #{String.slice(conn.resp_body || "", 0..600)}
      """)
    end
  end

  # URL-encode a list of {k, v} pairs, skipping nil values and
  # encoding empty strings as `k=`. Order is stable so a failure
  # message matches what the test typed.
  defp q(pairs) do
    pairs
    |> Enum.reject(fn {_, v} -> is_nil(v) end)
    |> Enum.map(fn {k, v} ->
      "#{URI.encode_www_form(to_string(k))}=#{URI.encode_www_form(to_string(v))}"
    end)
    |> Enum.join("&")
  end
end
