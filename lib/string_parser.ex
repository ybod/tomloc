defmodule Tomloc.StringParser do
  @moduledoc false

  @doc """
  Parser will parse string looking for %{pameter} and produce a function that accepts parameters in case any found

  ## Examples

  iex> Tomloc.StringParser.parse("Welcome to Tomloc!")
  {:str, "Welcome to Tomloc!"}

  iex> {:fun, fun} = Tomloc.StringParser.parse("Welcome to %{name}!!!")
  iex> fun.(name: "Tomloc")
  {:ok, "Welcome to Tomloc!!!"}

  iex> Tomloc.StringParser.parse("Welcome to %%{no_name}!!!")
  {:str, "Welcome to %{no_name}!!!"}

  iex> Tomloc.StringParser.parse("Welcome to %{name%{")
  {:error, {:invalid_param, "starts at pos.11", "symbol '%' found inside parameter name at pos.17"}}
  """
  def parse(str) do
    case do_parse(str, {0, <<>>}, {:str, []}) do
      {:str, [res]} -> {:str, res}
      {:fun, res} -> {:fun, fn params -> create_str(res, params, []) end}
      {:error, reason} -> {:error, reason}
    end
  end

  defp do_parse(<<>>, {_, parsed}, {res_type, res}),
    do: {res_type, [parsed | res]}

  defp do_parse(<<"%%{", str::binary>>, {i, parsed}, result) do
    do_parse(str, {i + 3, parsed <> "%{"}, result)
  end

  defp do_parse(<<"%{", str::binary>>, {i, parsed}, {_, res}) do
    case do_parse_param(str, i + 2, <<>>) do
      {:error, {:invalid_param, where}} ->
        {:error, {:invalid_param, "starts at pos.#{i}", where}}

      {param_length, param, rest} ->
        new_res = [String.to_atom(param) | [parsed | res]]
        do_parse(rest, {i + param_length, <<>>}, {:fun, new_res})
    end
  end

  defp do_parse(<<byte, str::binary>>, {i, parsed}, result) do
    do_parse(str, {i + 1, parsed <> <<byte>>}, result)
  end

  defp do_parse_param(<<>>, _, _) do
    {:error, {:invalid_param, "closing '}' not found"}}
  end

  defp do_parse_param(<<"%", _::binary>>, j, _) do
    {:error, {:invalid_param, "symbol '%' found inside parameter name at pos.#{j}"}}
  end

  defp do_parse_param(<<"}", rest::binary>>, j, param) do
    {j, param, rest}
  end

  defp do_parse_param(<<byte, rest::binary>>, j, param) do
    do_parse_param(rest, j + 1, param <> <<byte>>)
  end

  # Create string substituting params
  defp create_str([], _, res), do: {:ok, :erlang.list_to_binary(res)}

  defp create_str([h | t], params, res) when is_binary(h), do: create_str(t, params, [h | res])

  defp create_str([h | t], params, res) when is_atom(h) do
    case Keyword.fetch(params, h) do
      {:ok, param} -> create_str(t, params, [to_string(param) | res])
      :error -> {:error, {:invalid_param, "required parameter '#{h}' not found"}}
    end
  end
end
