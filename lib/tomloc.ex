defmodule Tomloc do
  @moduledoc """
  Tomloc GenServer
  """

  @doc false
  defmacro __using__(opts) do
    quote bind_quoted: [opts: opts] do
      use GenServer

      alias Tomloc.StringParser
      alias Tomloc.Core

      @otp_app Keyword.fetch!(opts, :otp_app)
      @fallback_lang Keyword.get(opts, :fallback_lang, :no_fallback)

      # Server (callbacks)
      @impl true
      def init(params) do
        ets_table = :ets.new(__MODULE__, [:set, :protected, {:read_concurrency, true}])

        {:ok, ets_table, {:continue, params}}
      end

      @impl true
      def handle_continue(params, ets_table) do
        tomloc_dir = Keyword.get(params, :localizations_dir) || Application.get_env(:tomloc, :tomloc_dir, "tomloc")

        tomlock_files =
          [Application.app_dir(@otp_app, "priv"), tomloc_dir, "*.toml"]
          |> Path.join()
          |> Path.wildcard()

        Enum.each(tomlock_files, fn tomloc_file ->
          basename = Path.basename(tomloc_file, ".toml")
          {:ok, tomloc} = Toml.decode_file(tomloc_file)

          process_tomloc(ets_table, basename, Map.to_list(tomloc))
        end)

        {:noreply, ets_table, :hibernate}
      end

      @impl true
      def handle_call(:get_table, _from, ets_table) do
        {:reply, ets_table, ets_table}
      end

      # Client
      def start_link(params \\ []) when is_list(params) do
        GenServer.start_link(__MODULE__, params, name: __MODULE__)
      end

      def get(loc_id, lang, params \\ [])
          when (is_binary(loc_id) or is_atom(loc_id)) and (is_binary(lang) or is_atom(lang)) do
        ets_table = GenServer.call(__MODULE__, :get_table)

        ets_id = "#{loc_id}_#{lang}"
        fallback_id = "#{loc_id}_#{@fallback_lang}"

        cond do
          :ets.member(ets_table, ets_id) -> get_translaction(ets_table, ets_id, params)
          :ets.member(ets_table, fallback_id) -> get_translaction(ets_table, fallback_id, params)
          true -> {:error, {:translation, "not found: id #{loc_id}, lang #{lang}, fallback lang #{@fallback_lang}"}}
        end
      end

      defp get_translaction(ets_table, ets_id, params) do
        case :ets.lookup_element(ets_table, ets_id, 2) do
          {:plain, str} -> {:ok, str}
          {:interpolated, interpolated_str} -> Core.format_interpolated_str(interpolated_str, params)
          {:list, list} -> {:ok, Enum.map(list, &process_list_el(&1, params))}
        end
      end

      def get!(loc_id, lang, params \\ [])
          when (is_binary(loc_id) or is_atom(loc_id)) and (is_binary(lang) or is_atom(lang)) do
        {:ok, str} = get(loc_id, lang, params)
        str
      end

      defp process_list_el({:plain, str}, _), do: str

      defp process_list_el({:interpolated, interpolated_str}, params) do
        {:ok, str} = Core.format_interpolated_str(interpolated_str, params)
        str
      end

      defp process_tomloc(_table, _basename, []), do: :noop

      defp process_tomloc(ets_table, basename, [{loc_id, langs} | tail])
           when is_binary(loc_id) and is_map(langs) do
        Enum.each(langs, fn {lang, transl} ->
          ets_id = "#{basename}_#{loc_id}_#{lang}"

          ets_record =
            if is_list(transl) do
              {:list, Enum.map(transl, &StringParser.parse(&1))}
            else
              StringParser.parse(transl)
            end

          insert(ets_id, ets_record, ets_table)
        end)

        process_tomloc(ets_table, basename, tail)
      end

      defp process_tomloc(ets_table, basename, [_head | tail]), do: process_tomloc(ets_table, basename, tail)

      defp insert(ets_id, ets_record, ets_table) when is_tuple(ets_record) do
        true = :ets.insert_new(ets_table, {ets_id, ets_record})
      end
    end
  end
end
