defmodule MemoTarTest do
  use ExUnit.Case
  doctest MemoTar

  test "open and close" do
    assert {:ok, memo_tar} = MemoTar.open()
    assert {:ok, content} = MemoTar.close(memo_tar)
    # Content consists only of end-of-archive entry (two 512 byte blocks of zero bytes)
    assert content == <<0::size(512*2*8)>>
    assert {:ok, []} = :erl_tar.extract({:binary, content}, [:memory])
  end

  test "open, write, and close" do
    assert {:ok, memo_tar} = MemoTar.open()
    assert :ok = MemoTar.add(memo_tar, "foo.txt", "Hello, world!")
    assert {:ok, content} = MemoTar.close(memo_tar)
    assert {:ok, [{'foo.txt', "Hello, world!"}]} = :erl_tar.extract({:binary, content}, [:memory])
  end

end
