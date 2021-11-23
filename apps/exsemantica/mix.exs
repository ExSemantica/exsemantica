defmodule Exsemantica.MixProject do
  use Mix.Project

  def project do
    [
      app: :exsemantica,
      version: "0.8.0",
      build_path: "../../_build",
      config_path: "../../config/config.exs",
      deps_path: "../../deps",
      lockfile: "../../mix.lock",
      elixir: "~> 1.12",
      start_permanent: Mix.env() == :prod,
      deps: deps()
    ]
  end

  # Run "mix help compile.app" to learn about applications.
  def application do
    [
      extra_applications: [:logger],
      mod: {Exsemantica.Application, []}
    ]
  end

  # Run "mix help deps" to learn about dependencies.
  defp deps do
    [
      # RATIONALE: Needed for the HTTP endpoints
      {:plug_cowboy, "~> 2.5"},

      # RATIONALE: Needed for the HTTP API
      {:absinthe, "~> 1.6"},
      {:absinthe_plug, "~> 1.5"},

      # All dependencies here are already in the project :P
      {:cloudclone, in_umbrella: true},
      {:extimeago, in_umbrella: true},
      {:ld_graph2, in_umbrella: true}
      # {:dep_from_hexpm, "~> 0.3.0"},
      # {:dep_from_git, git: "https://github.com/elixir-lang/my_dep.git", tag: "0.1.0"},
      # {:sibling_app_in_umbrella, in_umbrella: true}
    ]
  end
end
