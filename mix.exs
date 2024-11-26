defmodule ExRabbitPool.MixProject do
  use Mix.Project

  def project do
    [
      app: :ex_rabbit_pool,
      version: "1.2.0",
      elixir: "~> 1.14",
      start_permanent: Mix.env() == :prod,
      deps: deps(),
      test_coverage: [tool: ExCoveralls],
      docs: docs(),
      description: "RabbitMQ connection pool library",
      package: package(),
      source_url: "https://github.com/esl/ex_rabbit_pool"
    ]
  end

  defp docs do
    [
      main: "readme",
      formatters: ["html"],
      extras: [
        "README.md": [title: "Overview"]
      ]
    ]
  end

  defp package() do
    [
      files: ~w(lib .formatter.exs mix.exs README.md LICENSE),
      licenses: ["Apache 2"],
      links: %{
        "GitHub" => "https://github.com/esl/ex_rabbit_pool",
        "Blog Post" =>
          "https://www.erlang-solutions.com/blog/ex_rabbit_pool-open-source-amqp-connection-pool.html"
      }
    ]
  end

  def application do
    [
      extra_applications: [:logger]
    ]
  end

  defp deps do
    [
      {:amqp, "~> 4.0"},
      {:poolboy, "~> 1.5"},
      {:credo, "~> 1.7", only: [:dev, :test], runtime: false},
      {:ex_doc, "~> 0.18", only: :dev, runtime: false},
      {:excoveralls, "~> 0.18", only: [:dev, :test], runtime: false},
      {:dialyxir, "~> 1.4", only: [:dev, :test], runtime: false}
    ]
  end
end
