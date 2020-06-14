defmodule Seqfuzz.MixProject do
  use Mix.Project

  def project do
    [
      app: :seqfuzz,
      version: "0.1.0",
      elixir: "~> 1.10",
      start_permanent: Mix.env() == :prod,
      deps: deps(),
      docs: [
        main: "Seqfuzz"
      ]
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
