defmodule Tomloc.StringParserTest do
  @moduledoc false

  use ExUnit.Case, async: true
  doctest Tomloc.StringParser

  alias Tomloc.StringParser

  describe "StringParser can" do
    test "parse plain string into string" do
      assert {:plain, "Hello World"} == StringParser.parse("Hello World")
    end

    test "parse interpolated sting into list with parameter" do
      {:interpolated, [:name, "Hello "]} = StringParser.parse("Hello %{name}")
    end

    test "parse interpolated string into list with multiple parameters" do
      {:interpolated, [:three, :two, :one]} = StringParser.parse("%{one}%{two}%{three}")
    end

    test "escape parameter symbol %{" do
      assert {:plain, "%{"} == StringParser.parse("%%{")
      assert {:plain, "%%{"} == StringParser.parse("%%%{")
      assert {:plain, "%{not_param}"} == StringParser.parse("%%{not_param}")
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
