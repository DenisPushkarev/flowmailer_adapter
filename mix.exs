defmodule BambooFlowmailer.MixProject do
  use Mix.Project

  @source_url "https://github.com/dipushkarev/bamboo_flowmailer"

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
      links: %{"GitHub" => "https://github.com/kalys/bamboo_ses"}
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
