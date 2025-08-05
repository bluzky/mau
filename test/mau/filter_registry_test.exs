defmodule Mau.FilterRegistryTest do
  use ExUnit.Case, async: true
  doctest Mau.FilterRegistry

  alias Mau.FilterRegistry

  describe "get/1" do
    test "returns built-in string filters" do
      assert {:ok, {module, function}} = FilterRegistry.get(:upper_case)
      assert is_atom(module) and is_atom(function)

      assert {:ok, {module, function}} = FilterRegistry.get(:lower_case)
      assert is_atom(module) and is_atom(function)

      assert {:ok, {module, function}} = FilterRegistry.get(:capitalize)
      assert is_atom(module) and is_atom(function)
    end

    test "returns built-in number filters" do
      assert {:ok, {module, function}} = FilterRegistry.get(:round)
      assert is_atom(module) and is_atom(function)

      assert {:ok, {module, function}} = FilterRegistry.get(:format_currency)
      assert is_atom(module) and is_atom(function)
    end

    test "returns built-in collection filters" do
      assert {:ok, {module, function}} = FilterRegistry.get(:length)
      assert is_atom(module) and is_atom(function)

      assert {:ok, {module, function}} = FilterRegistry.get(:first)
      assert is_atom(module) and is_atom(function)

      assert {:ok, {module, function}} = FilterRegistry.get(:join)
      assert is_atom(module) and is_atom(function)
    end

    test "returns built-in math filters" do
      assert {:ok, {module, function}} = FilterRegistry.get(:abs)
      assert is_atom(module) and is_atom(function)

      assert {:ok, {module, function}} = FilterRegistry.get(:ceil)
      assert is_atom(module) and is_atom(function)

      assert {:ok, {module, function}} = FilterRegistry.get(:sqrt)
      assert is_atom(module) and is_atom(function)
    end

    test "returns error for unknown filter" do
      assert {:error, :not_found} = FilterRegistry.get(:unknown_filter)
    end

    test "normalizes string filter names to atoms" do
      assert {:ok, {module, function}} = FilterRegistry.get("upper_case")
      assert is_atom(module) and is_atom(function)
    end
  end

  describe "apply/3" do
    test "applies string filters correctly" do
      assert {:ok, "HELLO"} = FilterRegistry.apply(:upper_case, "hello", [])
      assert {:ok, "hello"} = FilterRegistry.apply(:lower_case, "HELLO", [])
      assert {:ok, "Hello"} = FilterRegistry.apply(:capitalize, "hello", [])
    end

    test "applies number filters correctly" do
      assert {:ok, 3} = FilterRegistry.apply(:round, 3.14159, [])
      assert {:ok, 3.14} = FilterRegistry.apply(:round, 3.14159, [2])
    end

    test "applies collection filters correctly" do
      assert {:ok, 3} = FilterRegistry.apply(:length, [1, 2, 3], [])
      assert {:ok, 1} = FilterRegistry.apply(:first, [1, 2, 3], [])
      assert {:ok, "1,2,3"} = FilterRegistry.apply(:join, [1, 2, 3], [","])
    end

    test "applies math filters correctly" do
      assert {:ok, 5} = FilterRegistry.apply(:abs, -5, [])
      assert {:ok, 4} = FilterRegistry.apply(:ceil, 3.14, [])
      assert {:ok, 4.0} = FilterRegistry.apply(:sqrt, 16, [])
    end

    test "returns error for unknown filter" do
      assert {:error, :filter_not_found} = FilterRegistry.apply(:unknown, "value", [])
    end

    test "handles filter errors gracefully" do
      # This should cause an error in sqrt (negative number)
      assert {:error, {:filter_error, _}} = FilterRegistry.apply(:sqrt, -1, [])
    end

    test "defaults args to empty list when not provided" do
      assert {:ok, "HELLO"} = FilterRegistry.apply(:upper_case, "hello")
    end
  end
end
