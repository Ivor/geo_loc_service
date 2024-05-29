defmodule GeoLocService.ErrorHelpersTest do
  use ExUnit.Case, async: true

  alias GeoLocService.GeoLocation
  alias GeoLocService.ErrorHelpers

  describe "translate_errors/1" do
    test "translates changeset errors for missing fields" do
      changeset = GeoLocation.changeset(%GeoLocation{}, %{})

      assert %{
               country_code: ["Country code can't be blank (Value: nil)"],
               ip_address: ["Ip address can't be blank (Value: nil)"],
               latitude: ["Latitude can't be blank (Value: nil)"],
               longitude: ["Longitude can't be blank (Value: nil)"]
             } = ErrorHelpers.translate_errors(changeset)
    end

    test "translate changeset errors for invalid values" do
      changeset =
        GeoLocation.changeset(%GeoLocation{}, %{
          ip_address: "1.1.1",
          longitude: 200.0,
          latitude: 100.0
        })

      assert %{
               ip_address: ["Ip address is not a valid IPv4 address (Value: 1.1.1)"],
               latitude: ["Latitude must be less than or equal to 90 (Value: 100.0)"],
               longitude: ["Longitude must be less than or equal to 180 (Value: 200.0)"],
               country_code: ["Country code can't be blank (Value: nil)"]
             } = ErrorHelpers.translate_errors(changeset)
    end
  end

  describe "full_error_string/1" do
    test "returns the errors as full strings" do
      changeset = GeoLocation.changeset(%GeoLocation{}, %{})

      full_error_string = ErrorHelpers.full_error_string(changeset)

      sorted_expectation =
        [
          "Country code can't be blank (Value: nil)",
          "Ip address can't be blank (Value: nil)",
          "Latitude can't be blank (Value: nil)",
          "Longitude can't be blank (Value: nil)"
        ]

      sorted_response =
        full_error_string
        |> String.split(". ")
        |> Enum.sort()

      assert sorted_expectation == sorted_response
    end
  end
end
