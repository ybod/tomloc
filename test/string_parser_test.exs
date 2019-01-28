defmodule Tomloc.StringParserTest do
  use ExUnit.Case, async: true
  doctest Tomloc.StringParser

  alias Tomloc.StringParser

  describe "StringParser can" do
    test "parse plain string into string" do
      assert {:str, "Hello World"} == StringParser.parse("Hello World")
    end

    test "parse string with a parameter info function" do
      {:fun, fun} = StringParser.parse("Hello %{name}")

      assert is_function(fun, 1)
      assert "Hello World" == fun.(name: "World")
    end

    test "return error for invalid parameter" do
      assert {:error, {:invalid_param, "starts at pos.6", "closing '}' not found"}} ==
               StringParser.parse("Hello %{name")

      assert {:error, {:invalid_param, "starts at pos.6", "symbol '%' found inside parameter name at pos.12"}} ==
               StringParser.parse("Hello %{name%}")

      assert {:error, {:invalid_param, "starts at pos.6", "symbol '%' found inside parameter name at pos.9"}} ==
               StringParser.parse("Hello %{n%{a}me}")
    end
  end
end
