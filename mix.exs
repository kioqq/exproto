defmodule Protobuf.MixProject do
  use Mix.Project

  def project do
    [
      app: :protobuf,
      version: "0.1.0",
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
      {:credo, "~> 0.8", only: [:dev, :test], runtime: false},
      {:ex_doc, "~> 0.14", only: :dev, runtime: false},
      {:eqc_ex, "~> 1.4", only: :test}
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
      maintainers: ["Evgeniy Evgrafov"],
      licenses: ["MIT"],
      links: %{"GitHub" => "https://github.com/kiopro/exproto"},
      files: ~w(mix.exs README.md lib config LICENSE priv/templates)
    ]
  end
end
