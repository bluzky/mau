defmodule Mau.WhitespaceProcessor do
  @moduledoc """
  Processes template AST to apply whitespace control based on trim options.

  This module takes an AST with trim options and applies whitespace trimming
  logic to adjacent text nodes.
  """

  @doc """
  Applies whitespace control to an AST based on trim options.

  Trims whitespace from adjacent text nodes when expressions or tags
  have trim_left or trim_right options set.

  ## Examples

      iex> nodes = [
      ...>   {:text, ["  before  "], []},
      ...>   {:expression, [{:variable, ["name"], []}], [trim_left: true]},
      ...>   {:text, ["  after  "], []}
      ...> ]
      iex> Mau.WhitespaceProcessor.apply_whitespace_control(nodes)
      [
        {:text, ["  before"], []},
        {:expression, [{:variable, ["name"], []}], [trim_left: true]},
        {:text, ["  after  "], []}
      ]
  """
  def apply_whitespace_control(nodes) when is_list(nodes) do
    apply_trim_processing(nodes, [])
  end

  # Main processing loop
  defp apply_trim_processing([], acc) do
    Enum.reverse(acc)
  end

  defp apply_trim_processing([node | rest], acc) do
    case should_trim_node(node) do
      {true, trim_options} ->
        # Apply trimming to adjacent text nodes
        {updated_acc, updated_rest} = apply_trim_to_adjacent(acc, rest, trim_options)
        apply_trim_processing(updated_rest, [node | updated_acc])

      {false, _} ->
        # No trimming needed
        apply_trim_processing(rest, [node | acc])
    end
  end

  # Check if a node needs trimming applied
  defp should_trim_node({_type, _parts, opts}) when is_list(opts) do
    trim_left = Keyword.get(opts, :trim_left, false)
    trim_right = Keyword.get(opts, :trim_right, false)

    if trim_left || trim_right do
      {true, %{trim_left: trim_left, trim_right: trim_right}}
    else
      {false, nil}
    end
  end

  # Handle non-3-tuple nodes or nodes without proper options list
  defp should_trim_node(_node) do
    {false, nil}
  end

  # Apply trimming to adjacent text nodes
  defp apply_trim_to_adjacent(acc, rest, trim_options) do
    updated_acc =
      if trim_options.trim_left do
        trim_left_whitespace(acc)
      else
        acc
      end

    updated_rest =
      if trim_options.trim_right do
        trim_right_whitespace(rest)
      else
        rest
      end

    {updated_acc, updated_rest}
  end

  # Trim whitespace from the right side of the last text node in accumulator
  defp trim_left_whitespace([{:text, [content], opts} | rest_acc]) do
    trimmed_content = String.trim_trailing(content)
    updated_node = {:text, [trimmed_content], opts}
    [updated_node | rest_acc]
  end

  defp trim_left_whitespace(acc) do
    # No text node to trim or not a text node at the end
    acc
  end

  # Trim whitespace from the left side of the first text node in remaining nodes
  defp trim_right_whitespace([{:text, [content], opts} | rest]) do
    trimmed_content = String.trim_leading(content)
    updated_node = {:text, [trimmed_content], opts}
    [updated_node | rest]
  end

  defp trim_right_whitespace(rest) do
    # No text node to trim or not a text node at the beginning
    rest
  end
end
