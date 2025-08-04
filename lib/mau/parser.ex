defmodule Mau.Parser do
  @moduledoc """
  Parser for the Mau template engine using NimbleParsec.
  
  Handles parsing of template strings into AST nodes.
  For Group 1, only handles plain text parsing.
  """

  import NimbleParsec
  alias Mau.AST.Nodes

  # For Group 1: Parse any text content - handle empty strings specially
  text_content =
    choice([
      utf8_string([], min: 1) |> reduce(:build_text_node),
      empty() |> reduce(:build_empty_text_node)
    ])

  defp build_text_node([content]) do
    Nodes.text_node(content)
  end

  defp build_empty_text_node([]) do
    Nodes.text_node("")
  end

  # Main template parser - for now just handles plain text
  defparsec(:parse_template, text_content)

  @doc """
  Parses a template string into an AST.
  
  For Group 1, only handles plain text templates.
  
  ## Examples
  
      iex> Mau.Parser.parse("Hello world")
      {:ok, {:text, ["Hello world"], []}}
      
      iex> Mau.Parser.parse("")
      {:ok, {:text, [""], []}}
  """
  def parse(template) when is_binary(template) do
    case parse_template(template) do
      {:ok, [ast], "", _, _, _} ->
        {:ok, ast}
      {:ok, [_ast], _remaining, _, _, _} ->
        # For Group 1, any remaining text is also just text
        {:ok, Nodes.text_node(template)}
      {:error, reason, _remaining, _context, {line, column}, _offset} ->
        error = Mau.Error.syntax_error("Parse error: #{reason}", line: line, column: column)
        {:error, error}
    end
  end
end