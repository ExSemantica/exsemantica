defmodule LdGraph2.MixProject do
  use Mix.Project

  def project do
    [
      app: :ld_graph2,
      version: "0.1.0",
      build_path: "../../_build",
      config_path: "../../config/config.exs",
      compilers: [:rust2ex] ++ Mix.compilers,
      deps_path: "../../deps",
      lockfile: "../../mix.lock",
      elixir: "~> 1.11",
      start_permanent: Mix.env() == :prod,
      deps: deps()
    ]
  end

  # Run "mix help compile.app" to learn about applications.
  def application do
    [
      extra_applications: [:logger]
    ]
  end

  # Run "mix help deps" to learn about dependencies.
  defp deps do
    [
      {:rust2ex, git: "https://github.com/Vor-Tech/Rust2Ex.git", tag: "v0.1.4"}
      # {:dep_from_hexpm, "~> 0.3.0"},
      # {:dep_from_git, git: "https://github.com/elixir-lang/my_dep.git", tag: "0.1.0"},
      # {:sibling_app_in_umbrella, in_umbrella: true}
    ]
  end
end
