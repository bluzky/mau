defmodule Mau.Error do
  @moduledoc """
  Error handling for the Mau template engine.
  
  Provides structured error information for different types of errors
  that can occur during template compilation and rendering.
  """

  defstruct [:type, :message, :line, :column, :source_file, :context]

  @type t :: %__MODULE__{
    type: :syntax | :runtime | :type | :undefined_variable,
    message: String.t(),
    line: integer() | nil,
    column: integer() | nil,
    source_file: String.t() | nil,
    context: map()
  }

  @doc """
  Creates a new syntax error.
  """
  def syntax_error(message, opts \\ []) do
    %__MODULE__{
      type: :syntax,
      message: message,
      line: opts[:line],
      column: opts[:column],
      source_file: opts[:source_file],
      context: opts[:context] || %{}
    }
  end

  @doc """
  Creates a new runtime error.
  """
  def runtime_error(message, opts \\ []) do
    %__MODULE__{
      type: :runtime,
      message: message,
      line: opts[:line],
      column: opts[:column],
      source_file: opts[:source_file],
      context: opts[:context] || %{}
    }
  end

  @doc """
  Creates a new type error.
  """
  def type_error(message, opts \\ []) do
    %__MODULE__{
      type: :type,
      message: message,
      line: opts[:line],
      column: opts[:column],
      source_file: opts[:source_file],
      context: opts[:context] || %{}
    }
  end

  @doc """
  Creates a new undefined variable error.
  """
  def undefined_variable_error(message, opts \\ []) do
    %__MODULE__{
      type: :undefined_variable,
      message: message,
      line: opts[:line],
      column: opts[:column],
      source_file: opts[:source_file],
      context: opts[:context] || %{}
    }
  end

  @doc """
  Formats an error for display.
  """
  def format(%__MODULE__{} = error) do
    type_name = error.type |> Atom.to_string() |> String.replace("_", " ") |> String.capitalize()
    
    location = case {error.line, error.column} do
      {nil, nil} -> ""
      {line, nil} -> " at line #{line}"
      {line, column} -> " at line #{line}, column #{column}"
    end

    source = if error.source_file, do: " in #{error.source_file}", else: ""
    
    "#{type_name}: #{error.message}#{location}#{source}"
  end
end