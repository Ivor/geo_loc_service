defmodule GeoLocService.GeoLocations do
  alias GeoLocService.GeoLocation

  import Ecto.Query

  @doc """
  Creates a new geo location with the given attributes.
  Returns `{:ok, geo_location}` if the geo location was created successfully, or `{:error, changeset}` if there were errors.
  """
  @spec create_geo_location(map(), Keyword.t()) ::
          {:ok, GeoLocation.t()} | {:error, Ecto.Changeset.t()}
  def create_geo_location(attrs, repo: repo) do
    %GeoLocation{}
    |> GeoLocation.changeset(attrs)
    |> repo.insert()
  end

  @doc """
  Fetches the geo location for the given IP address.
  Returns `{:ok, geo_location}` if the geo location was found, or `{:error, :not_found}` if it was not found.
  """
  @spec fetch_geo_location(binary(), Keyword.t()) :: {:ok, GeoLocation.t()} | {:error, :not_found}
  def fetch_geo_location(ip_address, repo: repo) do
    from(g in GeoLocation, where: g.ip_address == ^ip_address)
    |> repo.one()
    |> case do
      nil -> {:error, :not_found}
      geo_location -> {:ok, geo_location}
    end
  end
end
