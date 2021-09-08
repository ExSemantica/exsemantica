defmodule ExSemantica.MixProject do
  use Mix.Project

  def project do
    [
      apps_path: "apps",
      version: "0.5.1",
      start_permanent: Mix.env() == :prod,
      deps: deps(),
      releases: [
        exsemantica: [
          include_executables_for: [:unix],
          applications: [ 
            runtime_tools: :permanent,
            exsemantica_phx: :permanent,
            ld_graph2: :permanent,
            extimeago: :permanent
          ]
        ]
      ]
    ]
  end

  # Dependencies listed here are available only for this
  # project and cannot be accessed from applications inside
  # the apps folder.
  #
  # Run "mix help deps" for examples and options.
  defp deps do
    []
  end
end
