defmodule GeoLocService do
  require Logger

  @moduledoc """

  This service provides a way to import geo location data into a table called "geo_locations" and fetch geo locations by IP address.

  To use this library an Ecto.Repo is required to be configured.
  This Repo needs to have the table defined by the migration below to function correctly:

  ```elixir
  defmodule MyApp.Repo.Migrations.CreateGeoLocations do
    use Ecto.Migration

    def change do
      create table(:geo_locations) do
        add :ip_address, :string
        add :country_code, :string
        add :country, :string
        add :city, :string
        add :latitude, :decimal, precision: 15, scale: 13
        add :longitude, :decimal, precision: 16, scale: 13
        add :mystery_value, :bigint

        timestamps(type: :utc_datetime)
      end

      create index(:geo_locations, [:ip_address], unique: true)
    end
  end
  ```

  For the import functionality a CSV file is expected with the following columns:

  * IP Address
  * Country Code
  * Country
  * City
  * Latitude
  * Longitude
  * Mystery Value

  as well as the path where an error log file can be written.

  """

  alias GeoLocService.GeoLocations
  alias GeoLocService.ImportServer
  alias GeoLocService.Config

  @doc """
  Imports the given source into the database.

  The `source` is either the path to a local file or a url to a remote file.

  The options are:

  * `:error_file_path` - the path to the error log file
  * `:repo` - the Ecto repo

  These can be configured like this:

    ```elixir
    config :geo_loc_service,
      error_file_path: "error.log",
      repo: MyApp.Repo
    ```

  but can also optionally be passed as options to this function.

  This function returns `{:ok, "Done."}` if the import was completed successfully.
  If the import could not be started, it returns `{:error, reason}`.
  """
  @spec import(binary(), Keyword.t()) :: {:error, any()} | {:ok, binary()}
  def import(source, opts \\ []) when is_binary(source) do
    with {:ok, state_report} <-
           ImportServer.import(source, repo: repo!(opts), error_file_path: error_file_path!(opts)) do
      Logger.info(state_report)
      {:ok, "Done."}
    else
      {:error, reason} -> {:error, reason}
    end
  end

  @doc """
  Fetches the geo location for the given IP address.

  Returns `{:ok, geo_location}` if the geo location was found, or `{:error, :not_found}` if it was not found.
  """
  @spec fetch_geo_location(binary(), keyword()) ::
          {:error, :not_found} | {:ok, GeoLocService.GeoLocation.t()}
  def fetch_geo_location(ip_address, opts \\ []) do
    GeoLocations.fetch_geo_location(ip_address, repo: repo!(opts))
  end

  defp repo!(opts) do
    Keyword.get(opts, :repo) || Config.repo!()
  end

  defp error_file_path!(opts) do
    Keyword.get(opts, :error_file_path) || Config.error_file_path!()
  end
end
