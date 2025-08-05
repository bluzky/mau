defmodule Mau.Filters.Number do
  @moduledoc """
  Number formatting filters.
  """

  @doc """
  Returns the filter specification for this module.
  """
  def spec do
    %{
      category: :number,
      description: "Number formatting filters",
      filters: %{
        "format_currency" => %{
          description: "Formats number as currency",
          function: {__MODULE__, :format_currency}
        }
      }
    }
  end

  @doc """
  Formats a number as currency.
  """
  def format_currency(value, args) do
    case {value, args} do
      {num, []} when is_number(num) ->
        formatted = :erlang.float_to_binary(num / 1, decimals: 2)
        {:ok, "$#{formatted}"}

      {num, [currency_symbol]} when is_number(num) ->
        formatted = :erlang.float_to_binary(num / 1, decimals: 2)
        {:ok, "#{currency_symbol}#{formatted}"}

      _ ->
        {:error, "format_currency can only be applied to numbers"}
    end
  end
end
