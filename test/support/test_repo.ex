defmodule GeoLocService.TestRepo do
  def insert(changeset, opts \\ [])

  def insert(changeset, _opts) do
    Ecto.Changeset.apply_action(changeset, :insert)
  end
end
