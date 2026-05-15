defmodule Localize.Inputs.Playground.Gettext do
  @moduledoc """
  Gettext backend for the visualizer's UI strings.

  Hosts the message catalog used by `Localize.Inputs.Playground.Visualizer`
  and its view modules. The catalog lives in `priv/gettext/` and
  ships English source plus translations for the locales pre-bundled
  with the playground.

  Uses `Localize.Gettext.Interpolation` so all messages can use MF2
  (MessageFormat 2) syntax for placeholders, plural/select selectors,
  and inline markup — consistent with the rest of the Localize ecosystem.
  """
  use Gettext.Backend,
    otp_app: :localize_inputs_playground,
    interpolation: Localize.Gettext.Interpolation
end
