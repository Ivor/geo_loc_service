defmodule GeoLocService.GeoLocationTest do
  use ExUnit.Case, async: true

  alias GeoLocService.GeoLocation

  @valid_attrs %{
    ip_address: "1.1.1.1",
    country_code: "AU",
    country: "Australia",
    city: "Sydney",
    latitude: 33.8688,
    longitude: 151.2093,
    mystery_value: 1_234_567_890
  }

  describe "changeset/2" do
    test "changeset with valid data" do
      changeset = GeoLocation.changeset(%GeoLocation{}, @valid_attrs)

      assert changeset.valid?
    end

    test "validates that the ip address is a valid IPv4 address" do
      attrs = Map.put(@valid_attrs, :ip_address, "1.1.1")

      changeset = GeoLocation.changeset(%GeoLocation{}, attrs)

      assert {"is not a valid IPv4 address", [validation: :format]} =
               changeset.errors[:ip_address]
    end

    test "is valid if the data is good but the mystery value is not present" do
      attrs = Map.delete(@valid_attrs, :mystery_value)

      changeset = GeoLocation.changeset(%GeoLocation{}, attrs)

      assert changeset.valid?
    end

    test "validates the required fields" do
      [:ip_address, :country_code, :latitude, :longitude]
      |> Enum.each(fn field ->
        attrs = Map.delete(@valid_attrs, field)

        changeset = GeoLocation.changeset(%GeoLocation{}, attrs)
        assert {"can't be blank", [validation: :required]} = changeset.errors[field]
      end)
    end

    test "validates that the country code is a 2 letter string" do
      attrs = Map.put(@valid_attrs, :country_code, "AUS")

      changeset = GeoLocation.changeset(%GeoLocation{}, attrs)

      assert {"must be a 2-letter country code",
              [{:count, 2}, {:validation, :length}, {:kind, :is}, {:type, :string}]} =
               changeset.errors[:country_code]
    end

    test "validates that the country is included in our list of countries" do
      attrs = Map.put(@valid_attrs, :country_code, "XX")

      changeset = GeoLocation.changeset(%GeoLocation{}, attrs)

      assert {
               "is invalid",
               [
                 {:validation, :inclusion},
                 {:enum, _}
               ]
             } =
               changeset.errors[:country_code]
    end

    test "sets the country name if it is missing but the country code is valid" do
      attrs = Map.delete(@valid_attrs, :country)

      changeset = GeoLocation.changeset(%GeoLocation{}, attrs)

      assert %GeoLocation{} = changeset.data
      assert "Australia" = changeset.changes.country
    end
  end
end
