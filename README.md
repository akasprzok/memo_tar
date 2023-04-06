# MemoTar

You must have gotten truly lost to end up here.
This is an Elixir library for creating tar archives in memory.

## Usage

To create a tar archive in memory:

```elixir
  {:ok, binary} = MemoTar.create([{"foo.txt", "Hello World"}])
```

You can also add files one at a time.
However, this also currently requires that directories are added manually:

```elixir
  {:ok, tar} = MemoTar.open()
  :ok = MemoTar.add_directory(tar, "foo")
  :ok = MemoTar.add_file(tar, "foo/bar.txt", "Hello World")
  {:ok, binary} = MemoTar.close(tar)
```

## Installation

If [available in Hex](https://hex.pm/docs/publish), the package can be installed
by adding `tar_open` to your list of dependencies in `mix.exs`:

```elixir
def deps do
  [
    {:memo_tar, "~> 0.1.0"}
  ]
end
```

Documentation can be generated with [ExDoc](https://github.com/elixir-lang/ex_doc)
and published on [HexDocs](https://hexdocs.pm). Once published, the docs can
be found at <https://hexdocs.pm/tar_open>.

