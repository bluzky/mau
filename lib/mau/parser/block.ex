defmodule Mau.Parser.Block do
  @moduledoc """
  Block-level parsing for the Mau template engine.

  Handles parsing of:
  - Comment blocks ({# comment content #})
  - Text content (plain text with special character handling)
  - Template content orchestration
  """

  import NimbleParsec

  # ============================================================================
  # COMMENT BLOCK PARSING
  # ============================================================================

  @doc """
  Comment content parsing - anything up to #}.
  """
  def comment_content do
    repeat(
      choice([
        # Match # that's not followed by }
        string("#") |> lookahead_not(string("}")),
        # Match anything that's not #
        utf8_char(not: ?#)
      ])
    )
    |> reduce(:build_comment_content)
  end

  @doc """
  Comment block parsing with {# #} delimiters.
  """
  def comment_block do
    ignore(string("{#"))
    |> concat(comment_content())
    |> ignore(string("#}"))
    |> reduce(:build_comment_node)
  end

  # ============================================================================
  # TEXT CONTENT PARSING
  # ============================================================================

  @doc """
  Text content parsing that handles { characters not part of template constructs.
  """
  def text_content do
    choice([
      # Text that doesn't contain any { characters
      utf8_string([not: ?{], min: 1),
      # Handle { character that's not part of a template construct
      string("{")
      |> lookahead_not(choice([string("%"), string("{"), string("#")]))
      |> concat(repeat(utf8_char(not: ?{)))
      |> reduce(:join_chars)
    ])
    |> reduce(:build_text_node)
  end

  @doc """
  Template content orchestration - combines all block types.

  Requires: tag_block, expression_block from the main parser context.
  """
  def template_content(tag_block, expression_block) do
    choice([
      comment_block(),
      tag_block,
      expression_block,
      text_content()
    ])
  end
end
