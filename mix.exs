defmodule Glide.MixProject do
  use Mix.Project
  @url "https://github.com/maartenvanvliet/glid"
  def project do
    [
      app: :glide,
      version: "0.9.0",
      elixir: "~> 1.11",
      start_permanent: Mix.env() == :prod,
      deps: deps(),
      source_url: @url,
      homepage_url: @url,
      consolidate_protocols: Mix.env() != :test,
      description: "Library to help generating test data using StreamData",
      package: [
        maintainers: ["Maarten van Vliet"],
        licenses: ["MIT"],
        links: %{"GitHub" => @url},
        files: ~w(LICENSE README.md lib mix.exs)
      ],
      docs: [
        main: "Glide",
        canonical: "http://hexdocs.pm/glide",
        source_url: @url
      ]
    ]
  end

  # Run "mix help compile.app" to learn about applications.
  def application do
    [
      extra_applications: []
    ]
  end

  # Run "mix help deps" to learn about dependencies.
  defp deps do
    [
      {:stream_data, "~> 0.5.0"},
      {:ex_doc, "~> 0.23", only: [:dev, :test]},
      {:credo, "~> 1.5", only: [:dev, :test], runtime: false}
    ]
  end
end
