defmodule MauTest do
  use ExUnit.Case
  doctest Mau

  test "greets the world" do
    assert Mau.hello() == :world
  end
end
