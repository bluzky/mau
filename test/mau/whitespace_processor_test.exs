defmodule Mau.WhitespaceProcessorTest do
  use ExUnit.Case, async: true
  alias Mau.WhitespaceProcessor
  doctest Mau.WhitespaceProcessor

  describe "apply_whitespace_control/1" do
    test "leaves nodes without trim options unchanged" do
      nodes = [
        {:text, ["  before  "], []},
        {:expression, [{:variable, ["name"], []}], []},
        {:text, ["  after  "], []}
      ]
      
      result = WhitespaceProcessor.apply_whitespace_control(nodes)
      assert result == nodes
    end

    test "trims left whitespace from preceding text node" do
      nodes = [
        {:text, ["  before  "], []},
        {:expression, [{:variable, ["name"], []}], [trim_left: true]},
        {:text, ["  after  "], []}
      ]
      
      result = WhitespaceProcessor.apply_whitespace_control(nodes)
      
      expected = [
        {:text, ["  before"], []},
        {:expression, [{:variable, ["name"], []}], [trim_left: true]},
        {:text, ["  after  "], []}
      ]
      
      assert result == expected
    end

    test "trims right whitespace from following text node" do
      nodes = [
        {:text, ["  before  "], []},
        {:expression, [{:variable, ["name"], []}], [trim_right: true]},
        {:text, ["  after  "], []}
      ]
      
      result = WhitespaceProcessor.apply_whitespace_control(nodes)
      
      expected = [
        {:text, ["  before  "], []},
        {:expression, [{:variable, ["name"], []}], [trim_right: true]},
        {:text, ["after  "], []}
      ]
      
      assert result == expected
    end

    test "trims both left and right whitespace" do
      nodes = [
        {:text, ["  before  "], []},
        {:expression, [{:variable, ["name"], []}], [trim_left: true, trim_right: true]},
        {:text, ["  after  "], []}
      ]
      
      result = WhitespaceProcessor.apply_whitespace_control(nodes)
      
      expected = [
        {:text, ["  before"], []},
        {:expression, [{:variable, ["name"], []}], [trim_left: true, trim_right: true]},
        {:text, ["after  "], []}
      ]
      
      assert result == expected
    end

    test "handles multiple trim nodes in sequence" do
      nodes = [
        {:text, ["  start  "], []},
        {:expression, [{:variable, ["first"], []}], [trim_left: true]},
        {:text, ["  middle  "], []},
        {:expression, [{:variable, ["second"], []}], [trim_right: true]},
        {:text, ["  end  "], []}
      ]
      
      result = WhitespaceProcessor.apply_whitespace_control(nodes)
      
      expected = [
        {:text, ["  start"], []},
        {:expression, [{:variable, ["first"], []}], [trim_left: true]},
        {:text, ["  middle  "], []},
        {:expression, [{:variable, ["second"], []}], [trim_right: true]},
        {:text, ["end  "], []}
      ]
      
      assert result == expected
    end

    test "handles tag nodes with trim options" do
      nodes = [
        {:text, ["  before  "], []},
        {:tag, [:assign, "name", {:literal, ["value"], []}], [trim_left: true, trim_right: true]},
        {:text, ["  after  "], []}
      ]
      
      result = WhitespaceProcessor.apply_whitespace_control(nodes)
      
      expected = [
        {:text, ["  before"], []},
        {:tag, [:assign, "name", {:literal, ["value"], []}], [trim_left: true, trim_right: true]},
        {:text, ["after  "], []}
      ]
      
      assert result == expected
    end

    test "handles trim when no adjacent text nodes exist" do
      nodes = [
        {:expression, [{:variable, ["name"], []}], [trim_left: true, trim_right: true]}
      ]
      
      result = WhitespaceProcessor.apply_whitespace_control(nodes)
      
      # Should not modify the nodes when there are no text nodes to trim
      assert result == nodes
    end

    test "handles trim when adjacent nodes are not text nodes" do
      nodes = [
        {:expression, [{:variable, ["first"], []}], []},
        {:expression, [{:variable, ["second"], []}], [trim_left: true, trim_right: true]},
        {:expression, [{:variable, ["third"], []}], []}
      ]
      
      result = WhitespaceProcessor.apply_whitespace_control(nodes)
      
      # Should not modify when adjacent nodes are not text nodes
      assert result == nodes
    end

    test "handles newlines and tabs in whitespace trimming" do
      nodes = [
        {:text, ["  \n\t before \t\n  "], []},
        {:expression, [{:variable, ["name"], []}], [trim_left: true, trim_right: true]},
        {:text, ["  \n\t after \t\n  "], []}
      ]
      
      result = WhitespaceProcessor.apply_whitespace_control(nodes)
      
      expected = [
        {:text, ["  \n\t before"], []},
        {:expression, [{:variable, ["name"], []}], [trim_left: true, trim_right: true]},
        {:text, ["after \t\n  "], []}
      ]
      
      assert result == expected
    end

    test "handles empty text nodes after trimming" do
      nodes = [
        {:text, ["   "], []},
        {:expression, [{:variable, ["name"], []}], [trim_left: true]},
        {:text, ["   "], []}
      ]
      
      result = WhitespaceProcessor.apply_whitespace_control(nodes)
      
      expected = [
        {:text, [""], []},
        {:expression, [{:variable, ["name"], []}], [trim_left: true]},
        {:text, ["   "], []}
      ]
      
      assert result == expected
    end
  end
end