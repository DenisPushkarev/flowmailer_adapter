defmodule BambooFlowmailer.MixProject do
  use Mix.Project

  @source_url "https://github.com/DenisPushkarev/flowmailer_adapter"

  def project do
    [
      app: :bamboo_flowmailer,
      version: "0.1.0",
      elixir: "~> 1.12",
      start_permanent: Mix.env() == :prod,
      deps: deps(),
      description: "A Bamboo adapter for the FlowMailer email service",
      source_url: @source_url,
      package: package()
    ]
  end

  defp package do
    [
      name: :bamboo_flowmailer,
      description: "FlowMailer adapter for Bamboo",
      maintainers: ["Denis Pushkarev <dipushkarev@gmail.com>"],
      licenses: ["MIT"],
      links: %{"GitHub" => @source_url}
    ]
  end

  def application do
    [
      mod: {FlowMailer.Application, []},
      extra_applications: [:logger]
    ]
  end

  defp deps do
    [
      {:bamboo, "~> 2.0"},
      {:jason, "~> 1.2"},
      {:ex_doc, "> 0.0.0", only: :dev, runtime: false}
    ]
  end
end
