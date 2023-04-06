defmodule MemoTarTest do
  use ExUnit.Case
  doctest MemoTar

  describe "open/0" do
    test "open and close" do
      assert {:ok, memo_tar} = MemoTar.open()
      assert {:ok, content} = MemoTar.close(memo_tar)
      # Content consists only of end-of-archive entry (two 512 byte blocks of zero bytes)
      assert content == <<0::size(512*2*8)>>
      assert {:ok, []} = :erl_tar.extract({:binary, content}, [:memory])
    end

    test "open, write, and close" do
      assert {:ok, memo_tar} = MemoTar.open()
      assert :ok = MemoTar.add_file(memo_tar, "foo.txt", "Hello, world!")
      assert {:ok, content} = MemoTar.close(memo_tar)
      assert {:ok, [{'foo.txt', "Hello, world!"}]} = :erl_tar.extract({:binary, content}, [:memory])
    end

    test "write to a subdirectory" do
      assert {:ok, memo_tar} = MemoTar.open()
      assert :ok = MemoTar.add_file(memo_tar, "foo/bar.txt", "Hello, world!")
      assert :ok = MemoTar.add_directory(memo_tar, "foo")
      assert {:ok, content} = MemoTar.close(memo_tar)
      assert {:ok, [{'foo/bar.txt', "Hello, world!"}]} = :erl_tar.extract({:binary, content}, [:memory])
      # table also includes directory chunk
      assert {:ok, ['foo/bar.txt', 'foo']} = :erl_tar.table({:binary, content})
    end
  end

  test "create" do
    files = [
      {"foo/bar.txt", "Hello, world!"},
      {"foo.txt", "Hello, elixir!"},
    ]
    assert {:ok, content} = MemoTar.create(files)

    assert {:ok, [{'foo/bar.txt', "Hello, world!"}, {'foo.txt', "Hello, elixir!"}]} = :erl_tar.extract({:binary, content}, [:memory])
    assert {:ok, ['foo', 'foo/bar.txt', 'foo.txt']} = :erl_tar.table({:binary, content})
  end
end
