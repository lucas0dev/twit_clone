defmodule Support.UploadsCleaner do
  @moduledoc """
    It deletes uploads folders and creates new empty folders after each test.
  """

  defmacro __using__(_opts) do
    quote do
      setup do
        on_exit(fn -> delete_images() end)
      end

      def delete_images() do
        images =
          Path.join([
            :code.priv_dir(:twit_clone),
            "static",
            "uploads/"
          ])

        avatars =
          Path.join([
            :code.priv_dir(:twit_clone),
            "static",
            "avatars/"
          ])

        File.rm_rf(images)
        File.rm_rf(avatars)
        File.mkdir(images)
        File.mkdir(avatars)
      end
    end
  end
end
