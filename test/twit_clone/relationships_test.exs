defmodule TwitClone.RelationshipsTest do
  use TwitClone.DataCase

  alias TwitClone.Relationships
  import TwitClone.AccountsFixtures

  describe "create_relationship/2" do
    test "creates new relationship" do
      user1 = user_fixture()
      user2 = user_fixture()

      assert {:ok, _relationship} = Relationships.create_relationship(user1.id, user2.id)
      assert {:ok, _relationship} = Relationships.create_relationship(user2.id, user1.id)
    end

    test "does not create new relationship if follower_id = followed_id" do
      user1 = user_fixture()

      assert {:error, _} = Relationships.create_relationship(user1.id, user1.id)
    end

    test "does not create new relationship if it already exists" do
      user1 = user_fixture()
      user2 = user_fixture()
      Relationships.create_relationship(user1.id, user2.id)

      assert {:error, _} = Relationships.create_relationship(user1.id, user2.id)
    end
  end

  describe "delete_relationship/2" do
    test "deletes relationship is user_id == follower_id" do
      user1 = user_fixture()
      user2 = user_fixture()

      assert {:ok, relationship} = Relationships.create_relationship(user1.id, user2.id)
      assert {:ok, _} = Relationships.delete_relationship(relationship, user2.id)
    end

    test "doest not delete relationship is user_id != follower_id" do
      user1 = user_fixture()
      user2 = user_fixture()

      assert {:ok, relationship} = Relationships.create_relationship(user1.id, user2.id)
      assert {:error, :not_allowed} = Relationships.delete_relationship(relationship, user1.id)
      assert TwitClone.Repo.all(Relationships.Relationship) == [relationship]
    end
  end
end
