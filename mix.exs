defmodule Protobuf.MixProject do
  use Mix.Project

  def project do
    [
      app: :exproto,
      version: "0.2.1",
      elixir: "~> 1.6",
      build_embedded: Mix.env() == :prod,
      start_permanent: Mix.env() == :prod,
      deps: deps(),
      escript: escript(),
      description: description(),
      package: package()
    ]
  end

  def application do
    [extra_applications: [:logger]]
  end

  defp deps do
    [
      {:dialyxir, "~> 0.5", only: [:dev, :test], runtime: false},
      {:credo, "~> 1.0", only: [:dev, :test], runtime: false},
      {:ex_doc, "~> 0.14", only: :dev, runtime: false}
    ]
  end

  defp escript do
    [
      main_module: Protobuf.Protoc.CLI,
      name: "protoc-gen-elixir",
      app: nil
    ]
  end

  defp description do
    """
    Elixir protobuf library with protoc plugin.
    """
  end

  defp package do
    [
      maintainers: ["Evgeniy Abramov"],
      licenses: ["MIT"],
      links: %{"GitHub" => "https://github.com/kiopro/exproto"},
      files: ~w(mix.exs README.md lib config LICENSE priv/templates)
    ]
  end
end
