defmodule BambooFlowmailer.MixProject do
  use Mix.Project

  def project do
    [
      app: :bamboo_flowmailer,
      version: "0.1.0",
      elixir: "~> 1.12",
      start_permanent: Mix.env() == :prod,
      deps: deps(),
      package: package()
    ]
  end

  defp package do
    [
      description: "FlowMailer adapter for Bamboo",
      maintainers: ["Denis Pushkarev <dipushkarev@gmail.com>"],
      licenses: ["MIT"],
      links: %{"GitHub" => "git@github.com:DenisPushkarev/flowmailer_adapter"}
    ]
  end

  def application do
    [
      mod: {FlowMailer.Application, []},
      extra_applications: [:logger]
    ]
  end

  defp deps do
    [{:bamboo, "~> 2.0"}, {:jason, "~> 1.2"}]
  end
end
