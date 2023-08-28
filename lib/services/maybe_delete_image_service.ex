defmodule TwitClone.MaybeDeleteImageService do
  @moduledoc false

  @spec run(String.t()) :: :ok | {:error, atom}
  def run(path) do
    delete_file(path)
  end

  @spec run(String.t(), map()) :: :ok | {:error, atom}
  def run(path, params) do
    cond do
      params["remove-image"] == true -> delete_file(path)
      params["avatar"] != nil -> delete_file(path)
      params["image"] != nil -> delete_file(path)
      true -> :ok
    end
  end

  @spec delete_file(String.t()) :: :ok | {:error, atom}
  defp delete_file(path) do
    full_path =
      Path.join([
        :code.priv_dir(:twit_clone),
        "static",
        "/#{path}"
      ])

    File.rm(full_path)
  end
end
