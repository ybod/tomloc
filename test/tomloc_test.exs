defmodule TomlocTest do
  @moduledoc false

  use ExUnit.Case, async: true
  doctest Tomloc

  defmodule TomlocTester do
    @moduledoc false
    use Tomloc, otp_app: :tomloc
  end

  describe "Tomlock" do
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

    test "can return multiline string correctly" do
      {:ok, str} = TomlocTester.get(:example_multiline, :uk, three: 3.0)
      assert str == "Один:\n  - \"два\"\n  - 3.0"
    end

    test "returns error if translation id is incorrect" do
      {:error, {:translation, msg}} = TomlocTester.get(:wrong_id, :uk)
      assert msg == "not found: id wrong_id, lang uk, fallback lang no_fallback"
    end

    test "returns error if translation lang is incorrect" do
      {:error, {:translation, msg}} = TomlocTester.get("example_hello", :wrong_lang)
      assert msg == "not found: id example_hello, lang wrong_lang, fallback lang no_fallback"
    end

    test "can reload translations" do
      new_translation = """
      [brave_new_world]
      en = "Brave New World"
      uk = "Чудовий новий світ"
      """

      new_translation_path = Path.join([__DIR__, "/../priv/tomloc/", "reload.toml"])

      File.write!(new_translation_path, new_translation)

      :ok = TomlocTester.reload_translations()

      assert {:ok, "Brave New World"} == TomlocTester.get(:reload_brave_new_world, :en)
      assert {:ok, "Чудовий новий світ"} == TomlocTester.get(:reload_brave_new_world, :uk)

      File.rm!(new_translation_path)
    end
  end

  defmodule TomlocTesterFallback do
    @moduledoc false
    use Tomloc, otp_app: :tomloc, fallback_lang: :en
  end

  describe "Tomlock with fallback_lang" do
    setup do
      {:ok, _} = start_supervised(TomlocTesterFallback)
      :ok
    end

    test "returns translation for defined fallback lang if translation lang is incorrect" do
      assert "fallback" == TomlocTesterFallback.get!("example_fallback", :uk)
    end

    test "returns error if translation id is incorrect" do
      {:error, {:translation, msg}} = TomlocTesterFallback.get(:wrong_id, :uk)
      assert msg == "not found: id wrong_id, lang uk, fallback lang en"
    end
  end
end
