# MemoTar

This is a port from [`:erl_tar`](https://github.com/erlang/otp/blob/61c4f8ede7d9b15b6f7f5dcadd6127c8d56e3e35/lib/stdlib/src/erl_tar.erl).

It solves the problem of writting to a Tar file in memory, as asked in <https://elixirforum.com/t/in-memory-tar-file/47470/>.

Ported to Elixir with the help of fabulous <https://github.com/marianoguerra/efe>

`Tar` is a a patched port of the whole `:erl_tar` module.
`TarOpen` is a patched version of it offering only `TarOpen.open/2` as an alternative to `:erl_tar.open/2`
to be able to write to file loaded in RAM. Use this module if you just want to write to a tar file in memory.

## Usage


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

