# NOTICE: originally ported from
# https://github.com/erlang/otp/blob/61c4f8ede7d9b15b6f7f5dcadd6127c8d56e3e35/lib/stdlib/src/erl_tar.erl
# using https://github.com/marianoguerra/efe
defmodule TarOpen do
  require Record

  Record.defrecord(:r_file_info, :file_info,
    size: :undefined,
    type: :undefined,
    access: :undefined,
    atime: :undefined,
    mtime: :undefined,
    ctime: :undefined,
    mode: :undefined,
    links: :undefined,
    major_device: :undefined,
    minor_device: :undefined,
    inode: :undefined,
    uid: :undefined,
    gid: :undefined
  )

  Record.defrecord(:r_file_descriptor, :file_descriptor,
    module: :undefined,
    data: :undefined
  )

  Record.defrecord(:r_add_opts, :add_opts,
    read_info: :undefined,
    chunk_size: 0,
    verbose: false,
    atime: :undefined,
    mtime: :undefined,
    ctime: :undefined,
    uid: 0,
    gid: 0
  )

  Record.defrecord(:r_read_opts, :read_opts,
    cwd: :undefined,
    keep_old_files: false,
    files: :all,
    output: :file,
    open_mode: [],
    verbose: false
  )

  Record.defrecord(:r_tar_header, :tar_header,
    name: '',
    mode: 33188,
    uid: 0,
    gid: 0,
    size: 0,
    mtime: :undefined,
    typeflag: :undefined,
    linkname: '',
    uname: '',
    gname: '',
    devmajor: 0,
    devminor: 0,
    atime: :undefined,
    ctime: :undefined
  )

  Record.defrecord(:r_sparse_entry, :sparse_entry,
    offset: 0,
    num_bytes: 0
  )

  Record.defrecord(:r_sparse_array, :sparse_array, entries: [], is_extended: false, max_entries: 0)

  Record.defrecord(:r_header_v7, :header_v7,
    name: :undefined,
    mode: :undefined,
    uid: :undefined,
    gid: :undefined,
    size: :undefined,
    mtime: :undefined,
    checksum: :undefined,
    typeflag: :undefined,
    linkname: :undefined
  )

  Record.defrecord(:r_header_gnu, :header_gnu,
    header_v7: :undefined,
    magic: :undefined,
    version: :undefined,
    uname: :undefined,
    gname: :undefined,
    devmajor: :undefined,
    devminor: :undefined,
    atime: :undefined,
    ctime: :undefined,
    sparse: :undefined,
    real_size: :undefined
  )

  Record.defrecord(:r_header_star, :header_star,
    header_v7: :undefined,
    magic: :undefined,
    version: :undefined,
    uname: :undefined,
    gname: :undefined,
    devmajor: :undefined,
    devminor: :undefined,
    prefix: :undefined,
    atime: :undefined,
    ctime: :undefined,
    trailer: :undefined
  )

  Record.defrecord(:r_header_ustar, :header_ustar,
    header_v7: :undefined,
    magic: :undefined,
    version: :undefined,
    uname: :undefined,
    gname: :undefined,
    devmajor: :undefined,
    devminor: :undefined,
    prefix: :undefined
  )

  Record.defrecord(:r_reader, :reader,
    handle: :undefined,
    access: :undefined,
    pos: 0,
    func: :undefined
  )

  Record.defrecord(:r_reg_file_reader, :reg_file_reader,
    handle: :undefined,
    num_bytes: 0,
    pos: 0,
    size: 0
  )

  Record.defrecord(:r_sparse_file_reader, :sparse_file_reader,
    handle: :undefined,
    num_bytes: 0,
    pos: 0,
    size: 0,
    sparse_map: :EFE_TODO_NESTED_RECORD
  )

  def open({:binary, bin}, mode) when is_binary(bin) do
    do_open({:binary, bin}, mode)
  end

  def open({:file, fd}, mode) do
    do_open({:file, fd}, mode)
  end

  def open(name, mode)
      when is_list(name) or
             is_binary(name) do
    do_open(name, mode)
  end

  defp do_open(name, mode) when is_list(mode) do
    case open_mode(mode) do
      {:ok, access, raw, opts} ->
        open1(name, access, raw, opts)

      {:error, reason} ->
        {:error, {name, reason}}
    end
  end

  defp open1({:binary, bin0} = handle, :read, _Raw, opts)
       when is_binary(bin0) do
    bin =
      case :lists.member(:compressed, opts) do
        true ->
          try do
            :zlib.gunzip(bin0)
          catch
            _, _ ->
              bin0
          end

        false ->
          bin0
      end

    case :file.open(bin, [:ram, :binary, :read]) do
      {:ok, file} ->
        {:ok, r_reader(handle: file, access: :read, func: &file_op/2)}

      {:error, reason} ->
        {:error, {handle, reason}}
    end
  end

  defp open1({:file, fd} = handle, access, [:raw], opts) when access in [:read, :write] do
    case not :lists.member(:compressed, opts) do
      true ->
        reader = r_reader(handle: fd, access: access, func: &file_op/2)

        case do_position(reader, {:cur, 0}) do
          {:ok, pos, reader2} ->
            {:ok, r_reader(reader2, pos: pos)}

          {:error, reason} ->
            {:error, {handle, reason}}
        end

      false ->
        {:error, {handle, {:incompatible_option, :compressed}}}
    end
  end

  defp open1({:file, _Fd} = handle, :read, [], _Opts) do
    {:error, {handle, {:incompatible_option, :cooked}}}
  end

  defp open1(name, access, raw, opts)
       when is_list(name) or is_binary(name) do
    case :file.open(
           name,
           raw ++ [:binary, access | opts]
         ) do
      {:ok, file} ->
        {:ok, r_reader(handle: file, access: access, func: &file_op/2)}

      {:error, reason} ->
        {:error, {name, reason}}
    end
  end

  defp open_mode(mode) do
    open_mode(mode, false, [:raw], [])
  end

  defp open_mode(:read, _, raw, _) do
    {:ok, :read, raw, []}
  end

  defp open_mode(:write, _, raw, _) do
    {:ok, :write, raw, []}
  end

  defp open_mode([:read | rest], false, raw, opts) do
    open_mode(rest, :read, raw, opts)
  end

  defp open_mode([:write | rest], false, raw, opts) do
    open_mode(rest, :write, raw, opts)
  end

  defp open_mode([:compressed | rest], access, raw, opts) do
    open_mode(rest, access, raw, [:compressed, :read_ahead | opts])
  end

  defp open_mode([:cooked | rest], access, _Raw, opts) do
    open_mode(rest, access, [], opts)
  end

  defp open_mode([], access, raw, opts) do
    {:ok, access, raw, opts}
  end

  defp open_mode(_, _, _, _) do
    {:error, :einval}
  end

  defp file_op(:write, {fd, data}) do
    :file.write(fd, data)
  end

  defp file_op(:position, {fd, pos}) do
    :file.position(fd, pos)
  end

  defp file_op(:read2, {fd, size}) do
    :file.read(fd, size)
  end

  defp file_op(:close, fd) do
    :file.close(fd)
  end

  defp do_position(r_reader(handle: handle, func: fun) = reader, pos)
       when is_function(fun, 2) do
    case fun.(:position, {handle, pos}) do
      {:ok, newPos} ->
        {:ok, absPos} = fun.(:position, {handle, {:cur, 0}})
        {:ok, newPos, r_reader(reader, pos: absPos)}

      other ->
        other
    end
  end
end
