defmodule ExRabbitPool.MixProject do
  use Mix.Project

  def project do
    [
      app: :ex_rabbit_pool,
      version: "1.0.3",
      elixir: "~> 1.10.3 or ~> 1.11",
      start_permanent: Mix.env() == :prod,
      deps: deps(),
      test_coverage: [tool: ExCoveralls],
      description: "RabbitMQ connection pool library",
      package: package(),
      source_url: "https://github.com/esl/ex_rabbit_pool"
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
      {:amqp, "~> 3.0"},
      {:poolboy, "~> 1.5"},
      {:credo, "~> 1.7", only: [:dev, :test], runtime: false},
      {:ex_doc, "~> 0.18", only: :dev, runtime: false},
      {:excoveralls, "~> 0.18", only: [:dev, :test], runtime: false}
    ]
  end
end
