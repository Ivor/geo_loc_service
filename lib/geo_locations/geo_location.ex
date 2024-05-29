defmodule GeoLocService.GeoLocation do
  @moduledoc """
  A schema for storing geo location data.

  This schema is used to store information about a geo location, such as the IP address, country code, country, city, latitude, and longitude.

  The IP address must be a valid IPv4 address.
  The country code must be a valid alpha-2 country code which is maintained in the GeoLocService.Config.countries/0 function.
  The country name is set based on the country code.
  The city is not a required field.
  The latitude and longitude are validated to be within the correct range.

  The mystery value is a mystery.
  """

  use Ecto.Schema
  import Ecto.Changeset

  alias GeoLocService.Config

  @type t :: %__MODULE__{}

  # Regular expression for validating an IPv4 address.
  # 3 x (250-255 or 200-249 or 0-199 followed by a dot) then 250-255 or 200-249 or 0-199 to end the ip address.
  @ip_regex ~r/^((25[0-5]|2[0-4][0-9]|[01]?[0-9][0-9]?)\.){3}(25[0-5]|2[0-4][0-9]|[01]?[0-9][0-9]?)$/

  schema "geo_locations" do
    field :ip_address, :string
    field :country_code, :string
    field :country, :string
    field :city, :string
    field :latitude, :decimal
    field :longitude, :decimal
    field :mystery_value, :integer

    timestamps(type: :utc_datetime)
  end

  @doc false
  def changeset(geo_location, attrs) do
    geo_location
    |> cast(attrs, [
      :ip_address,
      :country_code,
      :country,
      :city,
      :latitude,
      :longitude,
      :mystery_value
    ])
    |> validate_required([:ip_address, :country_code, :latitude, :longitude])
    |> update_change(:country_code, &String.upcase/1)
    |> validate_country_code()
    |> validate_format(
      :ip_address,
      @ip_regex,
      message: "is not a valid IPv4 address"
    )
    |> validate_number(:latitude, greater_than_or_equal_to: -90, less_than_or_equal_to: 90)
    |> validate_number(:longitude, greater_than_or_equal_to: -180, less_than_or_equal_to: 180)
    |> set_country()
    |> unique_constraint(:ip_address, name: :geo_locations_ip_address_index)
  end

  defp validate_country_code(changeset) do
    with %{valid?: true} = changeset <-
           validate_length(changeset, :country_code,
             is: 2,
             message: "must be a 2-letter country code"
           ) do
      validate_inclusion(changeset, :country_code, Map.keys(Config.countries()))
    end
  end

  defp set_country(%{valid?: true} = changeset) do
    country_name =
      Config.countries()
      |> Map.get(get_field(changeset, :country_code))

    put_change(changeset, :country, country_name)
  end

  defp set_country(changeset), do: changeset
end
