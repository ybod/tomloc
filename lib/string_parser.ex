defmodule Tomloc.StringParser do
  @moduledoc """
  Parser will parse string looking for %{pameter} and produce a function that accepts parameters in case any found
  """

  @doc """
  ## Examples

  iex> Tomloc.StringParser.parse("Welcome to Tomloc!")
  {:str, "Welcome to Tomloc!"}

  iex> {:fun, fun} = Tomloc.StringParser.parse("Welcome to %{name}!!!")
  iex> fun.(name: "Tomloc")
  "Welcome to Tomloc!!!"

  iex> Tomloc.StringParser.parse("Welcome to %{name%{")
  {:error, {:invalid_param, "starts at pos.11", "symbol '%' found inside parameter name at pos.17"}}
  """
  def parse(str) do
    case do_parse(str, {0, <<>>}, {:str, []}) do
      {:str, _res} -> {:str, str}
      {:fun, res} -> {:fun, create_fun(res)}
      {:error, reason} -> {:error, reason}
    end
  end

  defp do_parse(<<>>, {_, parsed}, {res_type, res}),
    do: {res_type, [parsed | res]}

  defp do_parse(<<"%%{", str::binary>>, {i, parsed}, res) do
    do_parse(str, {i + 3, parsed <> "%%{"}, res)
  end

  defp do_parse(<<"%{", str::binary>>, {i, parsed}, {_, res}) do
    case do_parse_param(str, i + 2, <<>>) do
      {:error, {:invalid_param, where}} ->
        {:error, {:invalid_param, "starts at pos.#{i}", where}}

      {param_length, param, rest} ->
        new_res = {:fun, [String.to_atom(param) | [parsed | res]]}
        do_parse(rest, {i + param_length, <<>>}, new_res)
    end
  end

  defp do_parse(<<byte, str::binary>>, {i, parsed}, res) do
    do_parse(str, {i + 1, parsed <> <<byte>>}, res)
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

  defp create_fun(str_list) when is_list(str_list) do
    fn
      params ->
        str_list
        |> Enum.reduce([], fn
          elem, acc when is_binary(elem) -> [elem | acc]
          elem, acc when is_atom(elem) -> [Keyword.fetch!(params, elem) | acc]
        end)
        |> :erlang.list_to_binary()
    end
  end
end
