defmodule Mau.Filters.CollectionTest do
  use ExUnit.Case, async: true

  alias Mau.Filters.Collection

  describe "length/2" do
    test "returns length of list" do
      assert {:ok, 4} = Collection.length([1, 2, 3, 4], [])
    end

    test "returns 0 for empty list" do
      assert {:ok, 0} = Collection.length([], [])
    end

    test "returns length of string" do
      assert {:ok, 5} = Collection.length("hello", [])
    end

    test "returns size of map" do
      assert {:ok, 2} = Collection.length(%{"a" => 1, "b" => 2}, [])
    end

    test "errors on non-collection" do
      assert {:error, msg} = Collection.length(42, [])
      assert msg =~ "length can only be applied to collections or strings"
    end
  end

  describe "first/2" do
    test "returns first element of list" do
      assert {:ok, 1} = Collection.first([1, 2, 3], [])
    end

    test "returns nil for empty list" do
      assert {:ok, nil} = Collection.first([], [])
    end

    test "returns first character of string" do
      assert {:ok, "h"} = Collection.first("hello", [])
    end

    test "returns nil for empty string" do
      assert {:ok, nil} = Collection.first("", [])
    end

    test "errors on non-list/string" do
      assert {:error, msg} = Collection.first(42, [])
      assert msg =~ "first can only be applied to lists or strings"
    end
  end

  describe "last/2" do
    test "returns last element of list" do
      assert {:ok, 3} = Collection.last([1, 2, 3], [])
    end

    test "returns nil for empty list" do
      assert {:ok, nil} = Collection.last([], [])
    end

    test "returns last character of string" do
      assert {:ok, "o"} = Collection.last("hello", [])
    end

    test "returns nil for empty string" do
      assert {:ok, nil} = Collection.last("", [])
    end

    test "errors on non-list/string" do
      assert {:error, msg} = Collection.last(42, [])
      assert msg =~ "last can only be applied to lists or strings"
    end
  end

  describe "join/2" do
    test "joins list with separator" do
      assert {:ok, "a, b, c"} = Collection.join(["a", "b", "c"], [", "])
    end

    test "joins list with default separator when no arg" do
      assert {:ok, result} = Collection.join(["a", "b"], [])
      assert result =~ "a"
      assert result =~ "b"
    end

    test "joins list of integers" do
      assert {:ok, "1-2-3"} = Collection.join([1, 2, 3], ["-"])
    end

    test "joins single-element list" do
      assert {:ok, "a"} = Collection.join(["a"], [", "])
    end

    test "joins empty list" do
      assert {:ok, ""} = Collection.join([], [", "])
    end

    test "errors on non-list" do
      assert {:error, msg} = Collection.join("hello", [", "])
      assert msg =~ "join can only be applied to lists"
    end
  end

  describe "sort/2" do
    test "sorts list of integers ascending" do
      assert {:ok, [1, 2, 3, 4]} = Collection.sort([3, 1, 4, 2], [])
    end

    test "sorts list of strings alphabetically" do
      assert {:ok, ["apple", "banana", "cherry"]} =
               Collection.sort(["cherry", "apple", "banana"], [])
    end

    test "returns empty list unchanged" do
      assert {:ok, []} = Collection.sort([], [])
    end

    test "errors on non-list" do
      assert {:error, msg} = Collection.sort("hello", [])
      assert msg =~ "sort filter only supports lists"
    end
  end

  describe "reverse/2" do
    test "reverses a list" do
      assert {:ok, [3, 2, 1]} = Collection.reverse([1, 2, 3], [])
    end

    test "reverses a string" do
      assert {:ok, "olleh"} = Collection.reverse("hello", [])
    end

    test "returns empty list unchanged" do
      assert {:ok, []} = Collection.reverse([], [])
    end

    test "errors on non-list/string" do
      assert {:error, msg} = Collection.reverse(42, [])
      assert msg =~ "reverse can only be applied to lists or strings"
    end
  end

  describe "uniq/2" do
    test "removes duplicate integers" do
      assert {:ok, [1, 2, 3]} = Collection.uniq([1, 2, 2, 3, 1], [])
    end

    test "removes duplicate strings" do
      assert {:ok, ["a", "b"]} = Collection.uniq(["a", "b", "a"], [])
    end

    test "returns empty list unchanged" do
      assert {:ok, []} = Collection.uniq([], [])
    end

    test "returns list with no duplicates unchanged" do
      assert {:ok, [1, 2, 3]} = Collection.uniq([1, 2, 3], [])
    end

    test "errors on non-list" do
      assert {:error, msg} = Collection.uniq("hello", [])
      assert msg =~ "uniq can only be applied to lists"
    end
  end

  describe "slice/2" do
    test "slices list with start and length" do
      assert {:ok, [2, 3, 4]} = Collection.slice([1, 2, 3, 4, 5], [1, 3])
    end

    test "slices list from start to end" do
      assert {:ok, [3, 4, 5]} = Collection.slice([1, 2, 3, 4, 5], [2])
    end

    test "slices string with start and length" do
      assert {:ok, "ell"} = Collection.slice("hello", [1, 3])
    end

    test "slices string from start to end" do
      assert {:ok, "llo"} = Collection.slice("hello", [2])
    end

    test "returns empty list when start beyond length" do
      assert {:ok, []} = Collection.slice([1, 2, 3], [10])
    end

    test "errors without arguments" do
      assert {:error, msg} = Collection.slice([1, 2, 3], [])
      assert msg =~ "slice requires start index"
    end
  end

  describe "contains/2" do
    test "returns true when list contains value" do
      assert {:ok, true} = Collection.contains([1, 2, 3], [2])
    end

    test "returns false when list does not contain value" do
      assert {:ok, false} = Collection.contains([1, 2, 3], [5])
    end

    test "returns true when string contains substring" do
      assert {:ok, true} = Collection.contains("hello world", ["world"])
    end

    test "returns false when string does not contain substring" do
      assert {:ok, false} = Collection.contains("hello", ["xyz"])
    end

    test "returns true when map has key" do
      assert {:ok, true} = Collection.contains(%{"name" => "Alice"}, ["name"])
    end

    test "returns false when map does not have key" do
      assert {:ok, false} = Collection.contains(%{"name" => "Alice"}, ["age"])
    end

    test "errors without search value" do
      assert {:error, msg} = Collection.contains([1, 2], [])
      assert msg =~ "contains requires a value to search for"
    end
  end

  describe "compact/2" do
    test "removes nil values from list" do
      assert {:ok, [1, 2, 3]} = Collection.compact([1, nil, 2, nil, 3], [])
    end

    test "returns list unchanged when no nils" do
      assert {:ok, [1, 2, 3]} = Collection.compact([1, 2, 3], [])
    end

    test "returns empty list when all nils" do
      assert {:ok, []} = Collection.compact([nil, nil], [])
    end

    test "preserves false values" do
      assert {:ok, [1, false, 2]} = Collection.compact([1, nil, false, 2], [])
    end

    test "errors on non-list" do
      assert {:error, msg} = Collection.compact("hello", [])
      assert msg =~ "compact can only be applied to lists"
    end
  end

  describe "flatten/2" do
    test "flattens one level of nesting" do
      assert {:ok, [1, 2, 3, 4]} = Collection.flatten([[1, 2], [3, 4]], [])
    end

    test "flattens multiple levels of nesting" do
      assert {:ok, [1, 2, 3]} = Collection.flatten([[1, [2, [3]]]], [])
    end

    test "returns flat list unchanged" do
      assert {:ok, [1, 2, 3]} = Collection.flatten([1, 2, 3], [])
    end

    test "returns empty list unchanged" do
      assert {:ok, []} = Collection.flatten([], [])
    end

    test "errors on non-list" do
      assert {:error, msg} = Collection.flatten("hello", [])
      assert msg =~ "flatten can only be applied to lists"
    end
  end

  describe "sum/2" do
    test "sums list of integers" do
      assert {:ok, 10} = Collection.sum([1, 2, 3, 4], [])
    end

    test "sums list of floats" do
      assert {:ok, result} = Collection.sum([1.5, 2.5], [])
      assert_in_delta result, 4.0, 0.0001
    end

    test "sums mixed int and float" do
      assert {:ok, result} = Collection.sum([1, 2.5, 3], [])
      assert_in_delta result, 6.5, 0.0001
    end

    test "returns 0 for empty list" do
      assert {:ok, 0} = Collection.sum([], [])
    end

    test "errors when list contains non-numeric values" do
      assert {:error, msg} = Collection.sum([1, "two", 3], [])
      assert msg =~ "sum filter requires all elements to be numeric"
    end

    test "errors on non-list" do
      assert {:error, msg} = Collection.sum(42, [])
      assert msg =~ "sum can only be applied to lists"
    end
  end

  describe "keys/2" do
    test "returns keys of a map" do
      result = Collection.keys(%{"a" => 1, "b" => 2}, [])
      assert {:ok, keys} = result
      assert Enum.sort(keys) == ["a", "b"]
    end

    test "returns empty list for empty map" do
      assert {:ok, []} = Collection.keys(%{}, [])
    end

    test "errors on non-map" do
      assert {:error, msg} = Collection.keys([1, 2], [])
      assert msg =~ "keys can only be applied to maps"
    end
  end

  describe "values/2" do
    test "returns values of a map" do
      result = Collection.values(%{"a" => 1, "b" => 2}, [])
      assert {:ok, vals} = result
      assert Enum.sort(vals) == [1, 2]
    end

    test "returns empty list for empty map" do
      assert {:ok, []} = Collection.values(%{}, [])
    end

    test "errors on non-map" do
      assert {:error, msg} = Collection.values([1, 2], [])
      assert msg =~ "values can only be applied to maps"
    end
  end

  describe "group_by/2" do
    test "groups list of maps by field" do
      items = [
        %{"role" => "admin", "name" => "Alice"},
        %{"role" => "user", "name" => "Bob"},
        %{"role" => "admin", "name" => "Carol"}
      ]

      assert {:ok, grouped} = Collection.group_by(items, ["role"])
      assert length(grouped["admin"]) == 2
      assert length(grouped["user"]) == 1
    end

    test "returns empty map for empty list" do
      assert {:ok, %{}} = Collection.group_by([], ["role"])
    end

    test "skips non-map items" do
      items = [%{"role" => "admin"}, "not a map", 42]
      assert {:ok, grouped} = Collection.group_by(items, ["role"])
      assert Map.has_key?(grouped, "admin")
    end

    test "errors without field argument" do
      assert {:error, msg} = Collection.group_by([%{"a" => 1}], [])
      assert msg =~ "group_by requires a key field"
    end
  end

  describe "map/2" do
    test "extracts field values from list of maps" do
      items = [%{"name" => "Alice"}, %{"name" => "Bob"}]
      assert {:ok, ["Alice", "Bob"]} = Collection.map(items, ["name"])
    end

    test "filters out nil values and missing fields" do
      items = [
        %{"name" => "Alice"},
        %{"age" => 30},
        %{"name" => nil}
      ]

      assert {:ok, ["Alice"]} = Collection.map(items, ["name"])
    end

    test "returns empty list for empty input" do
      assert {:ok, []} = Collection.map([], ["name"])
    end

    test "returns empty list when no items have the field" do
      assert {:ok, []} = Collection.map([%{"a" => 1}], ["name"])
    end

    test "errors without field argument" do
      assert {:error, msg} = Collection.map([%{"a" => 1}], [])
      assert msg =~ "map requires a field name"
    end
  end

  describe "filter/2" do
    test "filters maps by field value" do
      items = [
        %{"active" => true, "name" => "Alice"},
        %{"active" => false, "name" => "Bob"},
        %{"active" => true, "name" => "Carol"}
      ]

      assert {:ok, result} = Collection.filter(items, ["active", true])
      assert length(result) == 2
      assert Enum.all?(result, &(&1["active"] == true))
    end

    test "returns empty list when no items match" do
      items = [%{"active" => false}]
      assert {:ok, []} = Collection.filter(items, ["active", true])
    end

    test "returns empty list for empty input" do
      assert {:ok, []} = Collection.filter([], ["active", true])
    end

    test "skips non-map items" do
      items = [%{"active" => true}, "not a map"]
      assert {:ok, result} = Collection.filter(items, ["active", true])
      assert length(result) == 1
    end

    test "errors without field and value arguments" do
      assert {:error, msg} = Collection.filter([%{"a" => 1}], [])
      assert msg =~ "filter requires field name and value"
    end
  end

  describe "reject/2" do
    test "rejects maps by field value" do
      items = [
        %{"active" => true, "name" => "Alice"},
        %{"active" => false, "name" => "Bob"},
        %{"active" => true, "name" => "Carol"}
      ]

      assert {:ok, result} = Collection.reject(items, ["active", false])
      assert length(result) == 2
      assert Enum.all?(result, &(&1["active"] == true))
    end

    test "returns all items when none match reject value" do
      items = [%{"active" => true}]
      assert {:ok, result} = Collection.reject(items, ["active", false])
      assert length(result) == 1
    end

    test "returns empty list for empty input" do
      assert {:ok, []} = Collection.reject([], ["active", false])
    end

    test "errors without field and value arguments" do
      assert {:error, msg} = Collection.reject([%{"a" => 1}], [])
      assert msg =~ "reject requires field name and value"
    end
  end

  describe "dump/2" do
    test "inspects a map" do
      assert {:ok, result} = Collection.dump(%{"key" => "val"}, [])
      assert is_binary(result)
      assert result =~ "key"
    end

    test "inspects a list" do
      assert {:ok, result} = Collection.dump([1, 2, 3], [])
      assert result =~ "1"
    end

    test "inspects nil" do
      assert {:ok, "nil"} = Collection.dump(nil, [])
    end
  end
end
