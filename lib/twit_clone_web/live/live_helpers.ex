defmodule TwitCloneWeb.LiveHelpers do
  @moduledoc """
    It provides functions shared between modules
  """

  def error_to_string(:not_accepted), do: "You have selected an unacceptable file type"
  def error_to_string(:too_many_files), do: "You have selected too many files"

  def to_simple_date(ecto_date) do
    Timex.format!(ecto_date, "{h24}:{m} {D}.{Mshort}.{YYYY} ")
  end
end
