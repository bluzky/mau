defmodule Mau.Parser.Tag do
  @moduledoc """
  Tag parsing for the Mau template engine.

  Handles parsing of template tags within `{% %}` blocks:
  - Assignment tags (assign)
  - Conditional tags (if, elsif, else, endif)  
  - Loop tags (for, endfor)
  """

  import NimbleParsec

  # ============================================================================
  # TAG PARSING FUNCTIONS
  # ============================================================================

  @doc """
  Assignment tag parsing - {% assign variable = expression %}.
  
  Requires: basic_identifier, pipe_expression, optional_whitespace, required_whitespace
  from the main parser context.
  """
  def assign_tag(basic_identifier, pipe_expression, optional_whitespace, required_whitespace) do
    ignore(string("assign"))
    |> ignore(required_whitespace)
    |> concat(basic_identifier)
    |> ignore(optional_whitespace)
    |> ignore(string("="))
    |> ignore(optional_whitespace)
    |> concat(pipe_expression)
    |> reduce({:build_tag, [:assign]})
  end

  @doc """
  If tag parsing - {% if condition %}.
  
  Requires: pipe_expression, required_whitespace from the main parser context.
  """
  def if_tag(pipe_expression, required_whitespace) do
    ignore(string("if"))
    |> ignore(required_whitespace)
    |> concat(pipe_expression)
    |> reduce({:build_tag, [:if]})
  end

  @doc """
  Elsif tag parsing - {% elsif condition %}.
  
  Requires: pipe_expression, required_whitespace from the main parser context.
  """
  def elsif_tag(pipe_expression, required_whitespace) do
    ignore(string("elsif"))
    |> ignore(required_whitespace)
    |> concat(pipe_expression)
    |> reduce({:build_tag, [:elsif]})
  end

  @doc """
  Else tag parsing - {% else %}.
  """
  def else_tag do
    ignore(string("else"))
    |> reduce({:build_tag, [:else]})
  end

  @doc """
  Endif tag parsing - {% endif %}.
  """
  def endif_tag do
    ignore(string("endif"))
    |> reduce({:build_tag, [:endif]})
  end

  @doc """
  For tag parsing - {% for item in collection %}.
  
  Requires: basic_identifier, pipe_expression, required_whitespace from the main parser context.
  """
  def for_tag(basic_identifier, pipe_expression, required_whitespace) do
    ignore(string("for"))
    |> ignore(required_whitespace)
    |> concat(basic_identifier)
    |> ignore(required_whitespace)
    |> ignore(string("in"))
    |> ignore(required_whitespace)
    |> concat(pipe_expression)
    |> reduce({:build_tag, [:for]})
  end

  @doc """
  Endfor tag parsing - {% endfor %}.
  """
  def endfor_tag do
    ignore(string("endfor"))
    |> reduce({:build_tag, [:endfor]})
  end

  # Note: Helper functions for tag building (build_tag, build_tag_node_with_trim, build_trim_opts)
  # remain in the main parser due to NimbleParsec's compilation model requiring helpers to be
  # in the same module as the combinators that use them
end