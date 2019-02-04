defmodule TomlocTest do
  @moduledoc false

  use ExUnit.Case
  doctest Tomloc

  setup do
    {:ok, _} = start_supervised(Tomloc)
    :ok
  end

  test "can return string with string key" do
    assert {:ok, "Привіт світ"} == Tomloc.get("example_hello", :uk)
  end

  test "can return string with atom key" do
    assert {:ok, "Bye Bye"} == Tomloc.get(:example_bye_bye, :en)
  end

  test "can return parameterized string" do
    assert {:ok, "Привіт, незнайомцю!"} == Tomloc.get(:example_param, :uk, name: "незнайомцю")
  end

  test "can return string lists" do
    assert {:ok, ["one", "2", "three"]} = Tomloc.get(:example_list, :en, two: 2)
  end
end
