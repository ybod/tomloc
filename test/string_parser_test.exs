defmodule Tomloc.StringParserTest do
  @moduledoc false

  use ExUnit.Case, async: true
  doctest Tomloc.StringParser

  alias Tomloc.StringParser

  describe "StringParser can" do
    test "parse plain string into string" do
      assert {:str, "Hello World"} == StringParser.parse("Hello World")
    end

    test "parse string with a parameter info a function" do
      {:fun, fun} = StringParser.parse("Hello %{name}")

      assert is_function(fun, 1)
      assert {:ok, "Hello World"} == fun.(name: "World")
    end

    test "parse string with multiple parameters into a function" do
      {:fun, fun} = StringParser.parse("%{one}%{two}%{three}%{four}")

      assert {:ok, "one2three"} == fun.(one: "one", two: 2, three: :three, four: nil)
    end

    test "escape parameter symbol %{" do
      assert {:str, "%{"} == StringParser.parse("%%{")
      assert {:str, "%%{"} == StringParser.parse("%%%{")
      assert {:str, "%{not_param}"} == StringParser.parse("%%{not_param}")
    end

    test "return error for invalid parameter" do
      assert {:error, {:invalid_param, "starts at pos.6", "closing '}' not found"}} ==
               StringParser.parse("Hello %{name")

      assert {:error, {:invalid_param, "starts at pos.6", "symbol '%' found inside parameter name at pos.12"}} ==
               StringParser.parse("Hello %{name%}")

      assert {:error, {:invalid_param, "starts at pos.6", "symbol '%' found inside parameter name at pos.9"}} ==
               StringParser.parse("Hello %{n%{a}me}")
    end

    test "return error if invalid parameter provided after sting with parameters parsed" do
      {:fun, fun} = StringParser.parse("Hello %{name}")

      assert {:error, {:invalid_param, "required parameter 'name' not found"}} = fun.(one: "two")
    end
  end
end
