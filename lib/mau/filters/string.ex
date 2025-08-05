defmodule Mau.Filters.String do
  @moduledoc """
  String manipulation filters.
  """

  @doc """
  Returns the filter specification for this module.
  """
  def spec do
    %{
      category: :string,
      description: "String manipulation and formatting filters",
      filters: %{
        "upper_case" => %{
          description: "Converts string to uppercase",
          function: {__MODULE__, :upper_case}
        },
        "lower_case" => %{
          description: "Converts string to lowercase",
          function: {__MODULE__, :lower_case}
        },
        "capitalize" => %{
          description: "Capitalizes the first letter of each word",
          function: {__MODULE__, :capitalize}
        },
        "strip" => %{
          description: "Removes whitespace from beginning and end",
          function: {__MODULE__, :strip}
        },
        "truncate" => %{
          description: "Truncates string to specified length",
          function: {__MODULE__, :truncate}
        },
        "default" => %{
          description: "Returns default value if input is nil or empty",
          function: {__MODULE__, :default}
        }
      }
    }
  end

  @doc """
  Converts a string to uppercase.
  """
  def upper_case(value, _args) do
    case value do
      str when is_binary(str) -> {:ok, String.upcase(str)}
      _ -> {:ok, to_string(value) |> String.upcase()}
    end
  end

  @doc """
  Converts a string to lowercase.
  """
  def lower_case(value, _args) do
    case value do
      str when is_binary(str) -> {:ok, String.downcase(str)}
      _ -> {:ok, to_string(value) |> String.downcase()}
    end
  end

  @doc """
  Capitalizes the first letter of each word in a string.
  """
  def capitalize(value, _args) do
    case value do
      str when is_binary(str) ->
        result =
          str
          |> String.split(" ")
          |> Enum.map(&String.capitalize/1)
          |> Enum.join(" ")

        {:ok, result}

      _ ->
        result = to_string(value) |> capitalize([])
        result
    end
  end

  @doc """
  Removes leading and trailing whitespace.
  """
  def strip(value, _args) do
    case value do
      str when is_binary(str) -> {:ok, String.trim(str)}
      _ -> {:ok, to_string(value) |> String.trim()}
    end
  end

  @doc """
  Truncates a string to the specified length.
  """
  def truncate(value, args) do
    case args do
      [length] when is_integer(length) and length >= 0 ->
        str = to_string(value)

        if String.length(str) <= length do
          {:ok, str}
        else
          {:ok, String.slice(str, 0, length)}
        end

      _ ->
        {:error, "truncate requires a positive integer length"}
    end
  end

  @doc """
  Returns a default value if the input is nil or empty string.
  """
  def default(value, args) do
    case args do
      [default_value] ->
        case value do
          nil -> {:ok, default_value}
          "" -> {:ok, default_value}
          _ -> {:ok, value}
        end

      _ ->
        {:error, "default requires a default value"}
    end
  end
end
