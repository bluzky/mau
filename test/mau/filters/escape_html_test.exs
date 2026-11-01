defmodule Mau.Filters.EscapeHtmlTest do
  use ExUnit.Case, async: true

  alias Mau.Filters.String, as: StringFilter

  describe "escape_html/2" do
    test "escapes every HTML special character" do
      assert {:ok, "&amp;&lt;&gt;&quot;&#x27;"} = StringFilter.escape_html(~s(&<>"'), [])
    end

    test "escapes & once, not the entities it produces" do
      assert {:ok, "&amp;lt;"} = StringFilter.escape_html("&lt;", [])
      assert {:ok, "&lt;"} = StringFilter.escape_html("<", [])
    end

    test "leaves safe text and non-ASCII unchanged" do
      assert {:ok, "héllo wörld"} = StringFilter.escape_html("héllo wörld", [])
      assert {:ok, ""} = StringFilter.escape_html("", [])
    end

    test "keeps nil, booleans and numbers" do
      assert {:ok, nil} = StringFilter.escape_html(nil, [])
      assert {:ok, true} = StringFilter.escape_html(true, [])
      assert {:ok, 42} = StringFilter.escape_html(42, [])
      assert {:ok, 1.5} = StringFilter.escape_html(1.5, [])
    end

    test "escapes strings nested in lists and maps" do
      assert {:ok, list} = StringFilter.escape_html(["<script>"], [])
      refute list =~ "<"

      assert {:ok, map} = StringFilter.escape_html(%{"a" => "<script>"}, [])
      refute map =~ "<script>"
    end
  end

  describe "in templates" do
    test "works as a filter and as a function" do
      context = %{"c" => "<script>alert('XSS')</script>"}
      expected = "<p>&lt;script&gt;alert(&#x27;XSS&#x27;)&lt;/script&gt;</p>"

      assert {:ok, ^expected} = Mau.render("<p>{{ c | escape_html }}</p>", context)
      assert {:ok, ^expected} = Mau.render("<p>{{ escape_html(c) }}</p>", context)
    end

    test "renders nil as empty" do
      assert {:ok, "[]"} = Mau.render("[{{ missing | escape_html }}]", %{})
    end

    test "escapes a list in the rendered output" do
      assert {:ok, output} = Mau.render("{{ l | escape_html }}", %{"l" => ["<b>"]})
      refute output =~ "<b>"
    end

    test "does not escape output by default" do
      assert {:ok, "<b>"} = Mau.render("{{ a }}", %{"a" => "<b>"})
    end
  end
end
