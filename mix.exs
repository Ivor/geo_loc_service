defmodule GeoLocService.MixProject do
  use Mix.Project

  def project do
    [
      app: :geo_loc_service,
      version: "0.1.0",
      elixir: "~> 1.16",
      elixirc_paths: elixirc_paths(Mix.env()),
      start_permanent: Mix.env() == :prod,
      deps: deps()
    ]
  end

  # Run "mix help compile.app" to learn about applications.
  def application do
    [
      extra_applications: [:logger],
      mod: {GeoLocService.Application, []}
    ]
  end

  defp elixirc_paths(:test), do: ["lib", "test/support"]
  defp elixirc_paths(_), do: ["lib"]

  # Run "mix help deps" to learn about dependencies.
  defp deps do
    [
      {:nimble_csv, "~> 1.1"},
      {:req, "~> 0.4.0"},
      {:ecto, "~> 3.10"},
      {:bypass, "~> 2.1", only: :test}
    ]
  end
end
