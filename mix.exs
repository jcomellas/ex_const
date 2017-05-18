defmodule Const.Mixfile do
  use Mix.Project

  def project do
    [app: :ex_const,
     version: "0.1.0",
     elixir: "~> 1.4",
     description: "Constants and Enumerated Values for Elixir"
     build_embedded: Mix.env == :prod,
     start_permanent: Mix.env == :prod,
     deps: deps(),
     package: package()]
  end

  # Configuration for the OTP application
  def application do
    # Specify extra applications you'll use from Erlang/Elixir
    [extra_applications: []]
  end

  defp deps do
    [{:ex_doc, "~> 0.15.1", only: :dev}]
  end

  defp package do
    [files: ["lib", "test", "mix.exs", "README*", "LICENSE*"],
     maintainers: ["Juan Jose Comellas"],
     licenses: ["Apache 2.0"],
     links: %{"GitHub" => "https://github.com/jcomellas/ex_const"}]
  end
end
