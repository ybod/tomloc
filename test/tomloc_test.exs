defmodule TomlocTest do
  @moduledoc false

  defmodule TomlocTester do
    @moduledoc false
    use Tomloc, otp_app: :tomloc
  end

  use ExUnit.Case
  doctest Tomloc

  setup do
    {:ok, _} = start_supervised(TomlocTester)
    :ok
  end

  test "can return string with string key" do
    assert {:ok, "Привіт світ"} == TomlocTester.get("example_hello", :uk)
  end

  test "can return string with atom key" do
    assert {:ok, "Bye Bye"} == TomlocTester.get(:example_bye_bye, :en)
  end

  test "can return parameterized string" do
    assert {:ok, "Привіт, незнайомцю!"} == TomlocTester.get(:example_param, :uk, name: "незнайомцю")
  end

  test "can return string lists" do
    assert {:ok, ["one", "2", "three"]} == TomlocTester.get(:example_list, :en, two: 2)
  end

  test "can return string list from array that contains empty strings" do
    assert {:ok, ["", "два", " ", ""]} == TomlocTester.get(:example_array, :uk, empty: "")
  end
end
