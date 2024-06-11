# GeoLocService

This library provides the GeoLocService interface. 
It can be used to import a CSV file of geo location data into a database via the `GeoLocService.import/2` function. 
It can also be used to retrieve the geo location data for a given IP address via the `GeoLocService.fetch_geo_location/2` function.

See the GeoLocService module for more information on the available functions.

## Configuration

### Repo

This service requires a configured Ecto.Repo 

```elixir
config :geo_loc_service, repo: MyApp.Repo
```

with a table called `geo_locations` defined by the following migration: 

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

### Error file

The import functionality will write to a configured error file for rows that do not import successfully. 
This value is set in the config file as `error_file_path`.

```elixir
config :geo_loc_service, error_file_path: "/path/to/error_file.txt"
```

## Usage

To use the library, add it as a dependency in your mix.exs file:

```elixir
{:geo_loc_service, git: "https://github.com/Ivor/geo_loc_service.git", tag: "0.1.0"}
```

Then run `mix deps.get` to install the dependency.

## Importing CSV files

```elixir
GeoLocService.import("/path/to/file.csv")
```

To override the configured error file path and repo these can be passed as options.
```elixir
GeoLocService.import("/path/to/file.csv", repo: MyApp.Repo, error_file_path: "/path/to/error_file.txt")
```

### Fetching geo location data

```elixir
GeoLocService.fetch_geo_location("1.1.1.1")
```

To override the configured repo this can be passed as an option.
```elixir
GeoLocService.fetch_geo_location("1.1.1.1", repo: MyApp.Repo)
```

## Testing

To run the tests, run `mix test` in the root directory of this project.

