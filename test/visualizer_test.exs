defmodule Localize.Inputs.Playground.VisualizerTest do
  use ExUnit.Case, async: false

  alias Localize.Inputs.Playground.Visualizer

  setup do
    conn = fn path, query ->
      :get
      |> Plug.Test.conn(path <> "?" <> URI.encode_query(query))
      |> Visualizer.call(Visualizer.init([]))
    end

    {:ok, conn: conn}
  end

  test "/ redirects to /number/input", %{conn: conn} do
    response = conn.("/", %{})
    assert response.status == 302
    assert Plug.Conn.get_resp_header(response, "location") == ["/number/input"]
  end

  test "/input renders form", %{conn: conn} do
    response = conn.("/number/input", %{"locale" => "en", "number_input" => "1,234.56"})
    assert response.status == 200
    assert response.resp_body =~ "Number Input Component"
    assert response.resp_body =~ "1234.56"
  end

  test "/parse renders the cross-locale table", %{conn: conn} do
    response = conn.("/number/parse", %{"input" => "1.234,56"})
    assert response.status == 200
    assert response.resp_body =~ "Cross-locale parsing"
    assert response.resp_body =~ "1234.56"
  end

  test "/format renders the cross-locale table", %{conn: conn} do
    response = conn.("/number/format", %{"amount" => "1234567.89"})
    assert response.status == 200
    assert response.resp_body =~ "Cross-locale formatting"
    assert response.resp_body =~ "1,234,567.89"
  end

  test "/locale renders per-locale table", %{conn: conn} do
    response = conn.("/number/locale", %{})
    assert response.status == 200
    assert response.resp_body =~ "Locale display data"
  end

  test "/assets/style.css served", %{conn: conn} do
    response = conn.("/assets/style.css", %{})
    assert response.status == 200
    assert response.resp_body =~ ".li-header"
  end

  test "/assets/localize_inputs.css served", %{conn: conn} do
    response = conn.("/assets/localize_inputs.css", %{})
    assert response.status == 200
    assert response.resp_body =~ ".number-input-wrapper"
  end

  test "/assets/localize_inputs.js served", %{conn: conn} do
    response = conn.("/assets/localize_inputs.js", %{})
    assert response.status == 200
    assert response.resp_body =~ "NumberInput"
  end

  test "unknown route 404s", %{conn: conn} do
    response = conn.("/does-not-exist", %{})
    assert response.status == 404
  end

  describe "/unit/input unit selection" do
    test "defaults to the locale's preferred unit", %{conn: conn} do
      assert selected_unit(conn, %{"locale" => "en", "category" => "length"}) == "inch"
      assert selected_unit(conn, %{"locale" => "de", "category" => "length"}) == "millimeter"
      assert selected_unit(conn, %{"locale" => "en", "category" => "mass"}) == "ounce"
    end

    test "resets when the category changes", %{conn: conn} do
      assert selected_unit(conn, %{
               "locale" => "en",
               "category" => "mass",
               "unit_input[amount]" => "5",
               "unit_input[unit]" => "meter"
             }) == "ounce"
    end

    test "resets when the locale changes", %{conn: conn} do
      assert selected_unit(conn, %{
               "locale" => "de",
               "category" => "length",
               "previous_locale" => "en",
               "unit_input[amount]" => "5",
               "unit_input[unit]" => "inch"
             }) == "millimeter"
    end

    test "keeps the user's unit when neither locale nor category changed", %{conn: conn} do
      assert selected_unit(conn, %{
               "locale" => "en",
               "category" => "length",
               "previous_locale" => "en",
               "unit_input[amount]" => "5",
               "unit_input[unit]" => "yard"
             }) == "yard"
    end

    test "honours a valid unit from a shared URL carrying no previous locale", %{conn: conn} do
      assert selected_unit(conn, %{
               "locale" => "de",
               "category" => "length",
               "unit_input[amount]" => "5",
               "unit_input[unit]" => "foot"
             }) == "foot"
    end

    test "falls back to the default for an unknown unit", %{conn: conn} do
      for bad <- ["", "garbage", "🙂", "meter-per-nonsense"] do
        assert selected_unit(conn, %{
                 "locale" => "en",
                 "category" => "length",
                 "unit_input[amount]" => "5",
                 "unit_input[unit]" => bad
               }) == "inch"
      end
    end

    test "emits the previous locale so the next submit can detect a switch", %{conn: conn} do
      response = conn.("/unit/input", %{"locale" => "de", "category" => "length"})
      assert response.resp_body =~ ~s(name="previous_locale" value="de")
    end
  end

  # The unit the rendered picker reports as selected, read
  # back out of its hidden carrier input.
  defp selected_unit(conn, params) do
    response = conn.("/unit/input", Map.put(params, "submitted", "1"))
    assert response.status == 200

    [_, unit] = Regex.run(~r/name="unit_input\[unit\]"[^>]*value="([^"]*)"/, response.resp_body)
    unit
  end
end
