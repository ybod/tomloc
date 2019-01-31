defmodule Tomlock.CoreTest do
  @moduledoc false

  use ExUnit.Case, async: true
  doctest Tomloc.Core

  alias Tomloc.Core

  describe "Core can format interpolated string" do
    test "with one parameter" do
      assert {:ok, "Hello Tomlock!"} == Core.format_interpolated_str(["!", :name, "Hello "], name: "Tomlock")
    end

    test "with multile parameters" do
      assert {:ok, "onetwo3"} ==
               Core.format_interpolated_str([:three, :two, :one], one: "one", two: :two, three: 3)
    end

    test "returning error if required parameter is absent" do
      assert {:error, {:invalid_param, "required parameter 'name' not found"}} ==
               Core.format_interpolated_str(["!", :name, "Hello "], no_name: "NoName")
    end
  end
end
