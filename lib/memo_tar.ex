defmodule MemoTar do
  @moduledoc """
  A convenience for creating tar files in memory.
  """

  use TypedStruct

  alias MemoTar.Tar

  typedstruct do
    field :file_device, IO.device()
    field :tar_device, IO.device()
  end

  @spec open :: {:ok, t()} | {:error, term()}
  def open do
    with {:ok, file_device} <- File.open("", [:read, :write, :ram]),
      {:ok, tar_device} <- Tar.open({:file, file_device}, [:write]) do
      {:ok, %__MODULE__{
        file_device: file_device,
        tar_device: tar_device
      }}
    end
  end

  @spec add(t(), String.t(), binary()) :: :ok
  def add(tar, path, content) do
    Tar.add(tar.tar_device, content, String.to_charlist(path), [])
  end

  def close(%__MODULE__{} = tar) do
    with :ok <- Tar.close(tar.tar_device),
      content <- read(tar.file_device),
      :ok <- File.close(tar.file_device) do
      {:ok, content}
    end
  end

  defp read(file) do
    file
    |> do_read(0, [])
    |> Enum.reverse()
    |> IO.iodata_to_binary()
  end

  defp do_read(file, position, acc) do
    chunk_size = 1024

    case :file.pread(file, position, chunk_size) do
      {:ok, data} ->
        do_read(file, position + chunk_size, [data | acc])

      :eof ->
        acc
    end
  end

end
