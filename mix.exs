defmodule ElixirGHAnalysis.Mixfile do
  use Mix.Project

  def project do
    [app: :elixir_gh_analysis,
     version: "0.1.0",
     elixir: "~> 1.4",
     build_embedded: Mix.env == :prod,
     start_permanent: Mix.env == :prod,
     deps: deps()]
  end

  # Configuration for the OTP application
  #
  # Type "mix help compile.app" for more information
  def application do
    # Specify extra applications you'll use from Erlang/Elixir
    [applications: [:logger, :httpoison, :ecto, :postgrex, :tzdata],
     mod: {ElixirGHAnalysis, []}]
  end

  # Dependencies can be Hex packages:
  #
  #   {:my_dep, "~> 0.3.0"}
  #
  # Or git/path repositories:
  #
  #   {:my_dep, git: "https://github.com/elixir-lang/my_dep.git", tag: "0.1.0"}
  #
  # Type "mix help deps" for more examples and options
  defp deps do
    [
      {:poison, "~> 3.1"},
      {:httpoison, "~> 0.11.1"},
      {:ecto, "~> 2.0"},
      {:postgrex, "~> 0.11"},
      {:timex, "~> 3.0"}
    ]
  end
end
