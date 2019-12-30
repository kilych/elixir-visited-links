defmodule VisitedLinks.Application do
  # See https://hexdocs.pm/elixir/Application.html
  # for more information on OTP Applications
  @moduledoc false

  use Application
  require Logger

  def start(_type, _args) do
    children = [
      {Plug.Cowboy, scheme: :http, plug: VisitedLinks.Router, options: [port: 8000]},
      {Redix, name: :redix, port: redis_port()}
    ]

    # See https://hexdocs.pm/elixir/Supervisor.html
    # for other strategies and supported options
    opts = [strategy: :one_for_one, name: VisitedLinks.Supervisor]

    Logger.info("Starting application...")

    Supervisor.start_link(children, opts)
  end

  defp redis_port(), do: Application.get_env(:visited_links, :redis_port, 6379)
end
