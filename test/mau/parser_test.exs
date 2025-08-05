defmodule Mau.ParserTest do
  use ExUnit.Case
  doctest Mau.Parser

  alias Mau.Parser

  describe "Group 1: Plain Text Parsing" do
    test "parses plain text" do
      assert {:ok, [{:text, ["Hello world"], []}]} = Parser.parse("Hello world")
    end

    test "parses empty text" do
      assert {:ok, []} = Parser.parse("")
    end

    test "parses multiline text" do
      text = "Line 1\nLine 2\nLine 3"
      assert {:ok, [{:text, [^text], []}]} = Parser.parse(text)
    end

    test "parses text with special characters" do
      text = "Special chars: !@#$%^&*()_+-=[]{}|;:,.<>?"
      assert {:ok, [{:text, [^text], []}]} = Parser.parse(text)
    end

    test "parses Unicode text" do
      text = "Hello 世界 🌍"
      assert {:ok, [{:text, [^text], []}]} = Parser.parse(text)
    end
  end
end
