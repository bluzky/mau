defmodule Mau.Filters.StringTest do
  use ExUnit.Case, async: true

  alias Mau.Filters.String, as: StringFilter

  describe "upper_case/2" do
    test "converts string to uppercase" do
      assert {:ok, "HELLO"} = StringFilter.upper_case("hello", [])
    end

    test "leaves already uppercase string unchanged" do
      assert {:ok, "HELLO"} = StringFilter.upper_case("HELLO", [])
    end

    test "handles mixed case" do
      assert {:ok, "HELLO WORLD"} = StringFilter.upper_case("Hello World", [])
    end

    test "handles empty string" do
      assert {:ok, ""} = StringFilter.upper_case("", [])
    end

    test "converts non-string via to_string" do
      assert {:ok, "123"} = StringFilter.upper_case(123, [])
    end
  end

  describe "lower_case/2" do
    test "converts string to lowercase" do
      assert {:ok, "hello"} = StringFilter.lower_case("HELLO", [])
    end

    test "leaves already lowercase string unchanged" do
      assert {:ok, "hello"} = StringFilter.lower_case("hello", [])
    end

    test "handles mixed case" do
      assert {:ok, "hello world"} = StringFilter.lower_case("Hello World", [])
    end

    test "handles empty string" do
      assert {:ok, ""} = StringFilter.lower_case("", [])
    end

    test "converts non-string via to_string" do
      assert {:ok, "true"} = StringFilter.lower_case(true, [])
    end
  end

  describe "capitalize/2" do
    test "capitalizes first letter" do
      assert {:ok, "Hello"} = StringFilter.capitalize("hello", [])
    end

    test "lowercases remaining letters" do
      assert {:ok, "Hello world"} = StringFilter.capitalize("HELLO WORLD", [])
    end

    test "handles empty string" do
      assert {:ok, ""} = StringFilter.capitalize("", [])
    end

    test "handles already capitalized string" do
      assert {:ok, "Hello"} = StringFilter.capitalize("Hello", [])
    end
  end

  describe "strip/2" do
    test "removes leading and trailing spaces" do
      assert {:ok, "hello"} = StringFilter.strip("  hello  ", [])
    end

    test "removes tabs and newlines" do
      assert {:ok, "hello"} = StringFilter.strip("\t\nhello\n\t", [])
    end

    test "returns empty string when only whitespace" do
      assert {:ok, ""} = StringFilter.strip("   ", [])
    end

    test "leaves string without whitespace unchanged" do
      assert {:ok, "hello"} = StringFilter.strip("hello", [])
    end

    test "converts non-string via to_string" do
      assert {:ok, "42"} = StringFilter.strip(42, [])
    end
  end

  describe "truncate/2" do
    test "truncates string longer than length with default suffix" do
      assert {:ok, "he..."} = StringFilter.truncate("hello world", [5])
    end

    test "returns string unchanged when shorter than length" do
      assert {:ok, "hi"} = StringFilter.truncate("hi", [10])
    end

    test "returns string unchanged when equal to length" do
      assert {:ok, "hello"} = StringFilter.truncate("hello", [5])
    end

    test "truncates with custom suffix" do
      assert {:ok, "hel--"} = StringFilter.truncate("hello world", [5, "--"])
    end

    test "truncates with empty suffix" do
      assert {:ok, "hello"} = StringFilter.truncate("hello world", [5, ""])
    end

    test "handles suffix longer than length by slicing suffix" do
      assert {:ok, "..."} = StringFilter.truncate("hello world", [3, "..."])
    end

    test "errors without length argument" do
      assert {:error, msg} = StringFilter.truncate("hello", [])
      assert msg =~ "truncate filter requires"
    end

    test "errors when value is not a string" do
      assert {:error, msg} = StringFilter.truncate(123, [5])
      assert msg =~ "truncate filter requires"
    end
  end

  describe "default/2" do
    test "returns default when value is nil" do
      assert {:ok, "fallback"} = StringFilter.default(nil, ["fallback"])
    end

    test "returns default when value is empty string" do
      assert {:ok, "fallback"} = StringFilter.default("", ["fallback"])
    end

    test "returns original value when not nil or empty" do
      assert {:ok, "actual"} = StringFilter.default("actual", ["fallback"])
    end

    test "returns non-string value as-is when present" do
      assert {:ok, 42} = StringFilter.default(42, ["fallback"])
    end

    test "returns false as-is (not treated as empty)" do
      assert {:ok, false} = StringFilter.default(false, ["fallback"])
    end

    test "errors without default argument" do
      assert {:error, msg} = StringFilter.default(nil, [])
      assert msg =~ "default requires a default value"
    end
  end
end
