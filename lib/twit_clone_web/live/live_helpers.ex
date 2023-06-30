defmodule TwitCloneWeb.LiveHelpers do
  @moduledoc """
    It has functions shared between modules
  """

  def error_to_string(:not_accepted), do: "You have selected an unacceptable file type"
  def error_to_string(:too_many_files), do: "You have selected too many files"
end
