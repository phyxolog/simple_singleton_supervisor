defmodule SimpleSingletonSupervisor.MixProject do
  use Mix.Project

  def project do
    [
      app: :simple_singleton_supervisor,
      version: "0.1.0",
      elixir: "~> 1.16",
      start_permanent: Mix.env() == :prod,
      description: description(),
      package: package(),
      deps: deps(),

      name: "SimpleSingletonSupervisor",
      source_url: "https://github.com/phyxolog/simple_singleton_supervisor",
      homepage_url: "https://github.com/phyxolog/simple_singleton_supervisor",
      docs: [
        main: "SimpleSingletonSupervisor",
        extras: ["README.md"],
        source_ref: "master"
      ]
    ]
  end

  def application do
    []
  end

  def deps do
    [
      {:ex_doc, "~> 0.31", only: :dev, runtime: false}
    ]
  end

  defp description do
    "Run a single globally unique process in a cluster"
  end

  defp package do
    [
      name: "simple_singleton_supervisor",
      licenses: ["MIT"],
      links: %{"GitHub" => "https://github.com/phyxolog/simple_singleton_supervisor"}
    ]
  end
end
