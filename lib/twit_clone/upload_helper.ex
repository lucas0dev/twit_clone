defmodule TwitClone.UploadHelper do
  @moduledoc "It provides helper functions connected to live_file_input"

  def delete_image(path) do
    full_path =
      Path.join([
        :code.priv_dir(:twit_clone),
        "static",
        "/#{path}"
      ])

    File.rm(full_path)
  end
end
