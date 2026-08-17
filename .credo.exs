%{
  configs: [
    %{
      name: "default",
      files: %{
        included: ["lib/", "test/", "config/", "mix.exs"],
        excluded: []
      },
      strict: true,
      checks: %{
        disabled: [
          # The visualizer views alias deeply-nested modules
          # (`Localize.Inputs.Number.{Components, Unit}`) and
          # then call them fully-qualified in a few places for
          # readability at the call site.
          {Credo.Check.Design.AliasUsage, []},

          # Aliases are grouped by origin (this app vs the
          # component libraries) rather than sorted
          # alphabetically.
          {Credo.Check.Readability.AliasOrder, []},

          # The render pipeline nests iodata construction
          # several levels deep by nature.
          {Credo.Check.Refactor.Nesting, []}
        ]
      }
    }
  ]
}
