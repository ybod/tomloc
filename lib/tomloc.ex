defmodule Tomloc do
  use GenServer

  # Server (callbacks)
  @impl true
  def init(params) do
    table = :ets.new(__MODULE__, [:set, :protected, {:read_concurrency, true}])

    send(self(), {:init, table, params})
    Process.register(self(), __MODULE__)

    {:ok, table}
  end

  @impl true
  def handle_info({:init, table, params}, _) do
    tomloc_dir = Keyword.get(params, :localizations_dir) || Application.get_env(:tomloc, :tomloc_dir)

    tomlock_files =
      [:code.priv_dir(:tomloc), tomloc_dir, "*.toml"]
      |> Path.join()
      |> Path.wildcard()

    Enum.each(tomlock_files, fn tomloc_file ->
      basename = Path.basename(tomloc_file, ".toml")
      {:ok, tomloc} = Toml.decode_file(tomloc_file)

      process_tomloc(table, basename, Map.to_list(tomloc))
    end)

    {:noreply, table, :hibernate}
  end

  @impl true
  def handle_call(:get_table, _from, table) do
    {:reply, table, table}
  end

  # Client
  def start_link(params \\ []) when is_list(params) do
    GenServer.start_link(__MODULE__, params)
  end

  def get(loc_id, lang) when is_atom(loc_id) and is_atom(lang) do
    table = GenServer.call(__MODULE__, :get_table)

    ets_id = :"#{loc_id}_#{lang}"
    :ets.lookup_element(table, ets_id, 2)
  end

  defp process_tomloc(_table, _basename, []), do: :noop

  defp process_tomloc(table, basename, [{loc_id, langs} | tail])
       when is_binary(loc_id) and is_map(langs) do
    Enum.each(langs, fn {lang, transl} ->
      ets_id = :"#{basename}_#{loc_id}_#{lang}"

      true = :ets.insert_new(table, {ets_id, transl})
    end)

    process_tomloc(table, basename, tail)
  end

  defp process_tomloc(table, basename, [_head | tail]), do: process_tomloc(table, basename, tail)
end
