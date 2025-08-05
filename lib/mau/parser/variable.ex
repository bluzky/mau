defmodule Mau.Parser.Variable do
  @moduledoc """
  Variable and identifier parsing for the Mau template engine.

  Handles parsing of:
  - Basic identifiers (user, name, index)  
  - Workflow identifiers ($input, $nodes, $variables)
  """

  import NimbleParsec
  alias Mau.AST.Nodes

  # ============================================================================
  # IDENTIFIER PARSING
  # ============================================================================

  # Identifier character definitions
  defp identifier_start, do: ascii_char([?a..?z, ?A..?Z, ?_])
  defp identifier_char, do: ascii_char([?a..?z, ?A..?Z, ?0..?9, ?_])

  # Basic identifier (user, name, index, etc.)
  defp basic_identifier do
    identifier_start()
    |> repeat(identifier_char())
    |> reduce(:build_identifier)
  end

  # Workflow variable identifier (starts with $)
  defp workflow_identifier do
    string("$")
    |> concat(basic_identifier())
    |> reduce(:build_workflow_identifier)
  end

  @doc """
  Parses any identifier - either workflow or basic.

  ## Examples

      * `user` -> basic identifier
      * `$input` -> workflow identifier  
      * `user_name` -> basic identifier
  """
  def identifier do
    choice([
      workflow_identifier(),
      basic_identifier()
    ])
  end

  # ============================================================================
  # HELPER FUNCTIONS
  # ============================================================================

  # Variable identifier helpers
  defp build_identifier(chars) do
    chars |> List.to_string()
  end

  defp build_workflow_identifier(["$", identifier]) do
    "$" <> identifier
  end
end