defmodule TomlocTest do
  use ExUnit.Case
  doctest Tomloc

  test "greets the world" do
    assert Tomloc.hello() == :world
  end
end
