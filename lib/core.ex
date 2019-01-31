defmodule Tomloc.Core do
  @moduledoc """
  Core logic
  """

  @doc """
  iex> Tomloc.Core.format_interpolated_str(["!!!", :name, "Welcome to "], name: "Tomloc")
  {:ok, "Welcome to Tomloc!!!"}
  """

  def format_interpolated_str(interpolated_str, params) when is_list(interpolated_str) do
    unless Keyword.keyword?(params) do
      raise ArgumentError
    end

    do_format_interpolated_str(interpolated_str, params, "")
  end

  defp do_format_interpolated_str([], _, res), do: {:ok, :erlang.list_to_binary(res)}

  defp do_format_interpolated_str([h | t], params, res) when is_binary(h),
    do: do_format_interpolated_str(t, params, [h | res])

  defp do_format_interpolated_str([h | t], params, res) when is_atom(h) do
    case Keyword.fetch(params, h) do
      {:ok, param} -> do_format_interpolated_str(t, params, [to_string(param) | res])
      :error -> {:error, {:invalid_param, "required parameter '#{h}' not found"}}
    end
  end
end
