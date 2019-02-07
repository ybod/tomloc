defmodule Tomloc.StringParser do
  @moduledoc false

  @doc """
  Parser will parse string looking for %{pameter} and produce a function that accepts parameters in case any found

  ## Examples

  iex> Tomloc.StringParser.parse("Welcome to Tomloc!")
  {:plain, "Welcome to Tomloc!"}

  iex> Tomloc.StringParser.parse("Welcome to %{name}!!!")
  {:interpolated, ["!!!", :name, "Welcome to "]}

  iex> Tomloc.StringParser.parse("Welcome to %%{no_name}!!!")
  {:plain, "Welcome to %{no_name}!!!"}

  iex> Tomloc.StringParser.parse("Welcome to %{name%{")
  {:error, {:invalid_param, "starts at pos.11", "symbol '%' found inside parameter name at pos.17"}}
  """
  def parse(""), do: {:plain, ""}

  def parse(str) do
    case do_parse(str, {0, <<>>}, {:plain, []}) do
      {:plain, [res]} -> {:plain, res}
      {:interpolated, res} -> {:interpolated, res}
      {:error, reason} -> {:error, reason}
    end
  end

  defp do_parse(<<>>, {_, ""}, {res_type, res}),
    do: {res_type, res}

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
        new_res = if parsed != "", do: [String.to_atom(param) | [parsed | res]], else: [String.to_atom(param) | res]
        do_parse(rest, {i + param_length, <<>>}, {:interpolated, new_res})
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
end
