defmodule Mau.BlockProcessor do
  @moduledoc """
  Processes template AST to convert individual conditional tags into block structures.
  
  This module takes a flat AST (list of nodes) and groups conditional tags
  (if/elsif/else/endif) into proper block structures for rendering.
  """

  @doc """
  Processes an AST to convert individual conditional tags into block structures.
  
  ## Examples
  
      iex> nodes = [
      ...>   {:tag, [:if, {:literal, [true], []}], []},
      ...>   {:text, ["Hello"], []},
      ...>   {:tag, [:endif], []}
      ...> ]
      iex> Mau.BlockProcessor.process_blocks(nodes)
      [
        {:conditional_block, [
          if_branch: {true, [{:text, ["Hello"], []}]},
          elsif_branches: [],
          else_branch: nil
        ], []}
      ]
  """
  def process_blocks(nodes) when is_list(nodes) do
    process_nodes(nodes, [])
  end

  # Main processing loop
  defp process_nodes([], acc) do
    Enum.reverse(acc)
  end

  defp process_nodes([{:tag, [:if, condition], opts} | rest], acc) do
    # Found an if tag - collect the entire conditional block
    case collect_conditional_block(rest, condition, [], [], nil) do
      {:ok, {block_node, remaining_nodes}} ->
        process_nodes(remaining_nodes, [block_node | acc])
      {:error, _reason} ->
        # If block collection fails, treat as individual tag
        process_nodes(rest, [{:tag, [:if, condition], opts} | acc])
    end
  end

  defp process_nodes([node | rest], acc) do
    # For non-if tags, just pass through
    process_nodes(rest, [node | acc])
  end

  # Collects nodes from if to endif, building a conditional block structure
  defp collect_conditional_block(nodes, if_condition, if_content, elsif_branches, else_content) do
    collect_conditional_block(nodes, if_condition, if_content, elsif_branches, else_content, [])
  end

  defp collect_conditional_block([], _if_condition, _if_content, _elsif_branches, _else_content, _remaining) do
    {:error, "Unclosed if statement - missing endif"}
  end

  defp collect_conditional_block([{:tag, [:elsif, condition], _opts} | rest], if_condition, if_content, elsif_branches, else_content, current_content) do
    # Found elsif - save current content to appropriate branch and start new elsif
    updated_branches = if current_content != [] do
      case elsif_branches do
        [] -> [{if_condition, Enum.reverse(current_content)}]
        _ -> elsif_branches ++ [{List.last(elsif_branches) |> elem(0), Enum.reverse(current_content)}]
      end
    else
      [{if_condition, Enum.reverse(if_content)} | elsif_branches]
    end
    
    collect_conditional_block(rest, if_condition, if_content, updated_branches ++ [{condition, []}], else_content, [])
  end

  defp collect_conditional_block([{:tag, [:else], _opts} | rest], if_condition, if_content, elsif_branches, _else_content, current_content) do
    # Found else - save current content and start collecting else content
    updated_branches = case {elsif_branches, current_content} do
      {[], []} -> []  # No elsif branches and no current content
      {[], content} -> [{if_condition, Enum.reverse(content)}]  # No elsif, but we have if content
      {branches, []} -> branches  # Have elsif branches, no current content
      {branches, content} -> 
        # Have elsif branches and current content - add current content to last elsif
        List.update_at(branches, -1, fn {cond, _} -> {cond, Enum.reverse(content)} end)
    end
    
    collect_conditional_block(rest, if_condition, if_content, updated_branches, [], [])
  end

  defp collect_conditional_block([{:tag, [:endif], _opts} | rest], if_condition, if_content, elsif_branches, else_content, current_content) do
    # Found endif - build the final conditional block
    final_if_content = if if_content != [], do: if_content, else: current_content
    final_else_content = if else_content != [] do
      else_content
    else
      case {elsif_branches, current_content} do
        {[], [_ | _] = content} -> content  # No elsif, current content is else
        {_branches, [_ | _] = content} -> content  # Have elsif, current content is else
        _ -> nil
      end
    end
    
    # Build the conditional block node
    final_else_branch = if final_else_content, do: Enum.reverse(final_else_content), else: nil
    
    block_data = [
      if_branch: {if_condition, Enum.reverse(final_if_content)},
      elsif_branches: elsif_branches,
      else_branch: final_else_branch
    ]
    
    block_node = {:conditional_block, block_data, []}
    {:ok, {block_node, rest}}
  end

  defp collect_conditional_block([node | rest], if_condition, if_content, elsif_branches, else_content, current_content) do
    # Regular node - add to current content
    collect_conditional_block(rest, if_condition, if_content, elsif_branches, else_content, [node | current_content])
  end
end