defmodule Swarm.MixProject do
  use Mix.Project

  def project do
    [
      app: :swarm_dynamic_supervisor,
      version: "0.1.0",
      elixir: "~> 1.6",
      start_permanent: Mix.env() == :prod,
      description: "Supervisor for Swarm registered processes to handle process crashes like regular DynamicSupervisor",
      deps: deps(),
      package: package(),
      # Docs
      name: "Swarm.DynamicSupervisor",
      source_url: "https://github.com/kelostrada/swarm_dynamic_supervisor",
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
      {:swarm, ">= 3.0.0"},
      {:ex_doc, "~> 0.16", only: :dev, runtime: false}
    ]
  end

  defp package do
    [files: ["lib", "mix.exs", "README.md"],
     maintainers: ["Bartosz Kalinowski"],
     licenses: ["MIT"],
     links: %{ "Github": "https://github.com/kelostrada/swarm_dynamic_supervisor" }]
  end
end
