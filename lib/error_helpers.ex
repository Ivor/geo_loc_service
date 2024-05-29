defmodule GeoLocService.ErrorHelpers do
  @moduledoc """
  Conveniences for translating and building error messages.
  """

  import Ecto.Changeset

  @doc """
  Translates the errors into 1 human-readable line.
  """
  def full_error_string(changeset) do
    translate_errors(changeset)
    |> Map.values()
    |> Enum.join(". ")
  end

  @doc """
  Traverses changeset errors and translates them using the given translator function.
  """
  def translate_errors(changeset) do
    traverse_errors(changeset, fn _changeset, key, error ->
      translate_error(key, error, get_field(changeset, key))
    end)
  end

  @doc """
  Translates an individual error message.

  Example response:
  "City can't be blank. (Value: nil)"
  """
  def translate_error(key, {msg, opts}, field_value) do
    interpolated_msg =
      opts
      |> Enum.reduce(msg, fn {key, opt_value}, acc ->
        acc
        |> String.replace("%{#{key}}", to_string(opt_value))
      end)

    field_name = humanize(Atom.to_string(key))

    [field_name, interpolated_msg, "(Value: #{as_string(field_value)})"]
    |> Enum.join(" ")
  end

  defp as_string(value) do
    case value do
      nil -> "nil"
      %Decimal{} -> Decimal.to_string(value)
      _ -> to_string(value)
    end
  end

  defp humanize(underscored_string) do
    underscored_string
    |> String.split("_")
    |> Enum.join(" ")
    |> String.capitalize()
  end
end
