defmodule TwitClone.Relationships.Relationship do
  @moduledoc false

  use Ecto.Schema
  import Ecto.Changeset

  @type t :: %__MODULE__{}

  schema "relationships" do
    field :followed_id, :id
    field :follower_id, :id
    timestamps()
  end

  def changeset(relationship, params) do
    relationship
    |> cast(params, [:followed_id, :follower_id])
    |> validate_required([:followed_id, :follower_id])
    |> validate_self_following()
    |> unique_constraint(
      [:followed_id, :follower_id],
      name: :relationships_followed_id_follower_id_index
    )
    |> unique_constraint(
      [:follower_id, :followed_id],
      name: :relationships_follower_id_followed_id_index
    )
  end

  defp validate_self_following(changeset) do
    case get_field(changeset, :followed_id) == get_field(changeset, :follower_id) do
      true -> add_error(changeset, :followed_id, "you can't follow yourself")
      false -> changeset
    end
  end
end
