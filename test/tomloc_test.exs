defmodule TomlocTest do
  use ExUnit.Case
  doctest Tomloc

  setup do
    {:ok, _} = start_supervised(Tomloc)
    :ok
  end

  test "can return string with string key" do
    assert "Привіт світ" == Tomloc.get("example_hello", :uk)
  end

  test "can return string with atom key" do
    assert "Bye Bye" == Tomloc.get(:example_bye_bye, :en)
  end

  test "can return parameterized string" do
    assert "Привіт, незнайомцю!" == Tomloc.get(:example_param, :uk, name: "незнайомцю")
  end
end
