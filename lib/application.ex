defmodule GeoLocService.Application do
  use Application

  def start(_type, _args) do
    children = [
      # Start the registry
      {Registry, keys: :unique, name: GeoLocService.Registry}
    ]

    opts = [strategy: :one_for_one, name: GeoLocService.Supervisor]
    Supervisor.start_link(children, opts)
  end
end
