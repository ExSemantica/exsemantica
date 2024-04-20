defmodule Exsemantica.MixProject do
  use Mix.Project

  def project do
    [
      app: :exsemantica,
      version: "0.10.0",
      elixir: "~> 1.16",
      elixirc_paths: elixirc_paths(Mix.env()),
      start_permanent: Mix.env() == :prod,
      aliases: aliases(),
      deps: deps()
    ]
  end

  # Run "mix help compile.app" to learn about applications.
  def application do
    [
      extra_applications: [:logger, :mnesia],
      mod: {Exsemantica.Application, []}
    ]
  end

  # Specifies which paths to compile per environment.
  defp elixirc_paths(:test), do: ["lib"]
  defp elixirc_paths(_), do: ["lib"]

  # Run "mix help deps" to learn about dependencies.
  defp deps do
    [
      # {:dep_from_hexpm, "~> 0.3.0"},
      # {:dep_from_git, git: "https://github.com/elixir-lang/my_dep.git", tag: "0.1.0"}

      # Keep code clean and organized.
      {:credo, "~> 1.7", only: [:dev, :test], runtime: false},

      # Create documentation for ExSemantica
      {:ex_doc, "~> 0.32", only: :dev, runtime: false},

      # Helps auto-constrain information to ASCII
      {:unidecode, "~> 1.0"},

      # Authentication
      {:guardian, "~> 2.3"},

      # Password hashing
      {:argon2_elixir, "~> 4.0"},

      # Web service
      {:bandit, "~> 1.4"},

      # Database adapter framework
      {:ecto, "~> 3.11"},

      # Database SQL store
      {:ecto_sql, "~> 3.11"},

      # Database adapter to connect to PostgreSQL
      {:postgrex, "~> 0.17"},

      # JSON library
      {:jason, "~> 1.4"},

      # Localize API messages
      {:gettext, "~> 0.24.0"}
    ]
  end

  defp aliases do
    [
      setup: ["deps.get", "ecto.setup"],
      "ecto.setup": ["ecto.create", "ecto.migrate", "run priv/repo/seeds.exs"],
      "ecto.reset": ["ecto.drop", "ecto.setup"],
      test: ["ecto.create --quiet", "ecto.migrate --quiet", "test"]
    ]
  end
end
