defmodule Mau.ConditionalIntegrationTest do
  use ExUnit.Case, async: true
  doctest Mau

  describe "conditional tag integration" do
    test "renders simple if tag (placeholder behavior)" do
      template = "{% if true %}Hello{% endif %}"
      context = %{}

      # For now, conditional tags just return empty strings (placeholder)
      # The content between tags is still rendered as text
      assert {:ok, result} = Mau.render(template, context)
      # Tags return empty, text content remains
      assert result == "Hello"
    end

    test "parses and renders if tag with variable condition" do
      template = "{% if user.active %}Welcome back!{% endif %}"
      context = %{"user" => %{"active" => true}}

      assert {:ok, result} = Mau.render(template, context)
      # Text content is rendered
      assert result == "Welcome back!"
    end

    test "handles false condition in if tag" do
      template = "{% if false %}Hidden content{% endif %}"
      context = %{}

      assert {:ok, result} = Mau.render(template, context)
      # Content should not render when condition is false
      assert result == ""
    end

    test "parses multiple conditional tags" do
      template = """
      {% if score >= 90 %}
      Excellent!
      {% elsif score >= 70 %}
      Good job!
      {% else %}
      Keep trying!
      {% endif %}
      """

      context = %{"score" => 85}

      assert {:ok, result} = Mau.render(template, context)
      # Only the matching elsif branch should render
      refute String.contains?(result, "Excellent!")
      assert String.contains?(result, "Good job!")
      refute String.contains?(result, "Keep trying!")
    end

    test "handles assignment within conditional blocks" do
      template = """
      {% assign name = "World" %}
      {% if true %}
      Hello {{ name }}!
      {% endif %}
      """

      context = %{}

      assert {:ok, result} = Mau.render(template, context)
      assert String.contains?(result, "Hello World!")
    end

    test "evaluates complex conditions" do
      template = "{% if age >= 18 and status == \"active\" %}Access granted{% endif %}"
      context = %{"age" => 25, "status" => "active"}

      assert {:ok, result} = Mau.render(template, context)
      assert String.contains?(result, "Access granted")
    end

    test "handles nested variable access in conditions" do
      template = "{% if user.profile.email %}User has email{% endif %}"

      context = %{
        "user" => %{
          "profile" => %{
            "email" => "user@example.com"
          }
        }
      }

      assert {:ok, result} = Mau.render(template, context)
      assert String.contains?(result, "User has email")
    end
  end
end
