defmodule Mau.NotOperatorTest do
  use ExUnit.Case, async: true
  alias Mau

  describe "not operator parsing and evaluation" do
    test "parses and evaluates not true" do
      template = "{{ not true }}"

      assert {:ok, result} = Mau.render(template, %{})
      assert result == "false"
    end

    test "parses and evaluates not false" do
      template = "{{ not false }}"

      assert {:ok, result} = Mau.render(template, %{})
      assert result == "true"
    end

    test "parses and evaluates not with variables" do
      template = "{{ not active }}"
      context = %{"active" => false}

      assert {:ok, result} = Mau.render(template, context)
      assert result == "true"
    end

    test "parses and evaluates not with truthy values" do
      template = "{{ not name }}"
      context = %{"name" => "Alice"}

      assert {:ok, result} = Mau.render(template, context)
      assert result == "false"
    end

    test "parses and evaluates not with falsy values" do
      template = "{{ not empty_string }}"
      context = %{"empty_string" => ""}

      assert {:ok, result} = Mau.render(template, context)
      assert result == "true"
    end

    test "parses and evaluates not with nil" do
      template = "{{ not missing_var }}"
      context = %{}

      assert {:ok, result} = Mau.render(template, context)
      assert result == "true"
    end

    test "parses and evaluates not with comparison" do
      template = "{{ not (age >= 18) }}"
      context = %{"age" => 16}

      assert {:ok, result} = Mau.render(template, context)
      assert result == "true"
    end

    test "parses and evaluates not in complex logical expression" do
      template = "{{ not active and verified }}"
      context = %{"active" => false, "verified" => true}

      assert {:ok, result} = Mau.render(template, context)
      assert result == "true"
    end

    test "parses and evaluates double not" do
      template = "{{ not not true }}"

      assert {:ok, result} = Mau.render(template, %{})
      assert result == "true"
    end

    test "not works in conditionals" do
      template = "{% if not active %}Inactive{% else %}Active{% endif %}"
      context = %{"active" => false}

      assert {:ok, result} = Mau.render(template, context)
      # not false = true, so if branch should execute
      assert result == "Inactive"
    end

    test "not has correct precedence with and/or" do
      template = "{{ not false and true }}"

      assert {:ok, result} = Mau.render(template, %{})
      # not false = true, true and true = true
      assert result == "true"
    end

    test "not works with parentheses for precedence override" do
      template = "{{ not (false and true) }}"

      assert {:ok, result} = Mau.render(template, %{})
      # false and true = false, not false = true
      assert result == "true"
    end
  end
end
