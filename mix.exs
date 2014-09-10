defmodule DmrWatch.Mixfile do
  use Mix.Project

  def project do
    [ app: :dmr_watch,
      version: "0.0.1",
      elixir: "~> 1.0.0-rc1 or ~> 1.0.0-rc2 or ~> 1.0.0",
      elixirc_paths: ["lib", "web"],
      deps: deps ]
  end

  # Configuration for the OTP application
  def application do
    [
      mod: { DmrWatch, [] },
      applications: [:phoenix, :cowboy, :logger, :httpoison, :ex_rated]
    ]
  end

  # Returns the list of dependencies in the format:
  # { :foobar, git: "https://github.com/elixir-lang/foobar.git", tag: "0.1" }
  #
  # To specify particular versions, regardless of the tag, do:
  # { :barbat, "~> 0.1", github: "elixir-lang/barbat" }
  defp deps do
    [
      {:phoenix, "~> 0.4.1"},
      {:cowboy, "~> 1.0.0"},
      {:httpoison, "~> 0.4.2"},
      {:timex, "~> 0.12.5"},
      {:ex_rated, "~> 0.0.3"},
      {:apex, "~> 0.3.0", only: :dev}
    ]
  end
end
