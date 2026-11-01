defmodule Mau.AtomSafetyTest do
  use ExUnit.Case, async: true

  alias Mau.AST.Nodes

  # Built at runtime so the atom never appears in compiled code
  defp unique_name(prefix) do
    "#{prefix}_#{System.unique_integer([:positive])}"
  end

  defp assert_no_atom(name) do
    assert_raise ArgumentError, fn -> String.to_existing_atom(name) end
  end

  describe "templates do not create atoms from" do
    test "property names" do
      name = unique_name("property")

      assert Mau.render("{{ user.#{name} }}", %{"user" => %{}}) == {:ok, ""}
      assert_no_atom(name)
    end

    test "root names in a path" do
      name = unique_name("root")

      assert Mau.render("{{ #{name}.x }}", %{}) == {:ok, ""}
      assert_no_atom(name)
    end

    test "names in strict mode" do
      property = unique_name("strict_property")
      root = unique_name("strict_root")

      assert {:error, _} = Mau.render("{{ user.#{property} }}", %{"user" => %{}}, strict_mode: true)
      assert {:error, _} = Mau.render("{{ #{root}.x }}", %{}, strict_mode: true)
      assert_no_atom(property)
      assert_no_atom(root)
    end

    test "atom literals" do
      name = unique_name("literal")

      assert {:ok, _ast} = Mau.compile("{{ :#{name} }}")
      assert Mau.render("{{ :#{name} }}", %{}) == {:ok, ":#{name}"}
      assert_no_atom(name)
    end

    test "atom literal nodes" do
      name = unique_name("node")

      assert Nodes.atom_literal_node(name) == {:literal, [":#{name}"], []}
      assert_no_atom(name)
    end
  end

  describe "existing atoms still work" do
    test "as root and property keys" do
      assert Mau.render("{{ user.name }}", %{user: %{name: "Al"}}) == {:ok, "Al"}
    end

    test "as keys holding nil" do
      assert Mau.render("{{ user.name }}", %{user: %{name: nil}}, strict_mode: true) == {:ok, ""}
    end

    test "as literals" do
      assert Nodes.atom_literal_node("ok") == {:literal, [:ok], []}
      assert Mau.render("{{ :ok }}", %{}) == {:ok, ":ok"}
      assert Mau.render("{{ :ok }}", %{}, preserve_types: true) == {:ok, :ok}
    end

    test "in comparisons with context values" do
      assert Mau.render("{{ status == :ok }}", %{"status" => :ok}) == {:ok, "true"}
      assert Mau.render("{{ status == :error }}", %{"status" => :ok}) == {:ok, "false"}
    end

    test "unknown atom literals compare as not equal" do
      name = unique_name("unknown")

      assert Mau.render("{{ status == :#{name} }}", %{"status" => :ok}) == {:ok, "false"}
    end
  end
end
