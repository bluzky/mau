defmodule Mau.CommentTest do
  use ExUnit.Case, async: true
  alias Mau

  describe "comment parsing and rendering" do
    test "parses basic comment block" do
      template = "Before {# This is a comment #} After"

      assert {:ok, result} = Mau.render(template, %{})
      assert result == "Before  After"
    end

    test "parses comment with no content" do
      template = "Before {##} After"

      assert {:ok, result} = Mau.render(template, %{})
      assert result == "Before  After"
    end

    test "parses comment with multiline content" do
      template = """
      Before
      {# This is a
         multiline comment #}
      After
      """

      assert {:ok, result} = Mau.render(template, %{})
      assert result == "Before\n\nAfter\n"
    end

    test "parses comment with special characters" do
      template = "Before {# Comment with @#$%^&*()_+ symbols #} After"

      assert {:ok, result} = Mau.render(template, %{})
      assert result == "Before  After"
    end

    test "handles multiple comments in template" do
      template = "Start {# comment 1 #} Middle {# comment 2 #} End"

      assert {:ok, result} = Mau.render(template, %{})
      assert result == "Start  Middle  End"
    end

    test "comments work with expressions" do
      template = "Hello {# user comment #} {{ name }} {# end comment #}"
      context = %{"name" => "Alice"}

      assert {:ok, result} = Mau.render(template, context)
      assert result == "Hello  Alice "
    end

    test "comments work with tags" do
      template = "Before {# comment #} {% assign x = 5 %} After"

      assert {:ok, result} = Mau.render(template, %{})
      assert result == "Before   After"
    end
  end
end
