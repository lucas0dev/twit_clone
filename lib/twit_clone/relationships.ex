defmodule TwitClone.Relationships do
  @moduledoc false

  import Ecto.Query, warn: false

  alias TwitClone.Repo
  alias TwitClone.Relationships.Relationship

  @spec create_relationship(non_neg_integer(), non_neg_integer()) ::
          {:ok, Relationship.t()} | {:error, map()}
  def create_relationship(followed_id, follower_id) do
    attrs = %{"followed_id" => followed_id, "follower_id" => follower_id}

    %Relationship{}
    |> Relationship.changeset(attrs)
    |> Repo.insert()
  end

  @spec delete_relationship(Relationship.t(), non_neg_integer()) ::
          {:ok, Relationship.t()} | {:error, map()} | {:error, :not_allowed}
  def delete_relationship(%Relationship{follower_id: user_id} = relationship, user_id) do
    case Repo.delete(relationship) do
      {:ok, relationship} -> {:ok, relationship}
      {:error, _changeset} -> {:error, :changeset_error}
    end
  end

  def delete_relationship(%Relationship{}, _) do
    {:error, :not_allowed}
  end
end
