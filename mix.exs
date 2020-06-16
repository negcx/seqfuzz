defmodule Seqfuzz.MixProject do
  use Mix.Project

  def project do
    [
      app: :seqfuzz,
      version: "0.2.0",
      elixir: "~> 1.10",
      start_permanent: Mix.env() == :prod,
      deps: deps(),
      source_url: "https://github.com/negcx/seqfuzz",
      docs: [
        main: "Seqfuzz"
      ],
      description: "Sublime Text-like sequential fuzzy string matching for Elixir.",
      package: package()
    ]
  end

  defp package do
    [
      maintainers: ["Kyle Johnson"],
      licenses: ["MIT"],
      links: %{"GitHub" => "https://github.com/negcx/seqfuzz"}
    ]
  end

  def application do
    [
      extra_applications: [:logger]
    ]
  end

  defp deps do
    [
      {:ex_doc, "0.22.1", onLy: :dev, runtime: false}
    ]
  end
end
