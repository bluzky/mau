defmodule Mau.BlockProcessor do
  @moduledoc """
  Processes template AST to convert individual conditional tags into block structures.

  This module takes a flat AST (list of nodes) and groups conditional tags
  (if/elsif/else/endif) into proper block structures for rendering.
  """

  # State management for conditional block collection
  defmodule ConditionalBlockState do
    @moduledoc false
    defstruct [
      :if_condition,
      if_content: [],
      elsif_branches: [],
      else_content: nil,
      current_content: [],
      current_branch: :if
    ]
  end

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

  defp process_nodes([{:tag, [:for, loop_variable, collection_expression], opts} | rest], acc) do
    # Found a for tag - collect the entire loop block
    case collect_loop_block(rest, loop_variable, collection_expression) do
      {:ok, {block_node, remaining_nodes}} ->
        process_nodes(remaining_nodes, [block_node | acc])

      {:error, _reason} ->
        # If block collection fails, treat as individual tag
        process_nodes(rest, [{:tag, [:for, loop_variable, collection_expression], opts} | acc])
    end
  end

  defp process_nodes([node | rest], acc) do
    # For non-block-starting tags, just pass through
    process_nodes(rest, [node | acc])
  end

  # Collects nodes from if to endif, building a conditional block structure
  defp collect_conditional_block(nodes, if_condition, if_content, elsif_branches, else_content) do
    state = %ConditionalBlockState{
      if_condition: if_condition,
      if_content: if_content,
      elsif_branches: elsif_branches,
      else_content: else_content,
      current_content: [],
      current_branch: :if
    }

    collect_conditional_block(nodes, state)
  end

  defp collect_conditional_block([], _state) do
    {:error, "Unclosed if statement - missing endif"}
  end

  defp collect_conditional_block([{:tag, [:elsif, condition], _opts} | rest], state) do
    # Save current content and switch to new elsif branch
    updated_state =
      state
      |> save_current_branch_content()
      |> add_elsif_branch(condition)

    collect_conditional_block(rest, updated_state)
  end

  defp collect_conditional_block([{:tag, [:else], _opts} | rest], state) do
    # Save current content and switch to else branch
    updated_state =
      state
      |> save_current_branch_content()
      |> switch_to_else_branch()

    collect_conditional_block(rest, updated_state)
  end

  defp collect_conditional_block([{:tag, [:endif], _opts} | rest], state) do
    # Finalize the conditional block
    final_state = save_current_branch_content(state)

    # Build the conditional block node
    final_else_branch =
      if final_state.else_content != nil and final_state.else_content != [],
        do: process_blocks(final_state.else_content),
        else: nil

    block_data = [
      if_branch: {final_state.if_condition, process_blocks(final_state.if_content)},
      elsif_branches: process_elsif_branches(final_state.elsif_branches),
      else_branch: final_else_branch
    ]

    block_node = {:conditional_block, block_data, []}
    {:ok, {block_node, rest}}
  end

  defp collect_conditional_block([{:tag, [:if, nested_condition], _nested_opts} | rest], state) do
    # Found nested if - recursively process it as a complete conditional block
    case collect_conditional_block(rest, nested_condition, [], [], nil) do
      {:ok, {nested_block, remaining_nodes}} ->
        # Add the processed nested block to current content
        updated_state = add_node_to_current_content(state, nested_block)
        collect_conditional_block(remaining_nodes, updated_state)

      {:error, error} ->
        {:error, error}
    end
  end

  defp collect_conditional_block([node | rest], state) do
    # Regular node - add to current content
    updated_state = add_node_to_current_content(state, node)
    collect_conditional_block(rest, updated_state)
  end

  # Collects nodes from for to endfor, building a loop block structure
  defp collect_loop_block(nodes, loop_variable, collection_expression) do
    collect_loop_block(nodes, loop_variable, collection_expression, [], 0)
  end

  defp collect_loop_block([], _loop_variable, _collection_expression, _content, _depth) do
    {:error, "Unclosed for statement - missing endfor"}
  end

  defp collect_loop_block(
         [{:tag, [:for, _, _], _opts} = node | rest],
         loop_variable,
         collection_expression,
         content,
         depth
       ) do
    # Found nested for - increment depth and add to content
    collect_loop_block(rest, loop_variable, collection_expression, [node | content], depth + 1)
  end

  defp collect_loop_block(
         [{:tag, [:endfor], _opts} = node | rest],
         loop_variable,
         collection_expression,
         content,
         depth
       ) do
    if depth > 0 do
      # This endfor belongs to a nested for - decrement depth and add to content
      collect_loop_block(rest, loop_variable, collection_expression, [node | content], depth - 1)
    else
      # This is the matching endfor for our loop - build the final loop block
      # Process nested content for any conditional blocks
      processed_content = process_blocks(Enum.reverse(content))

      block_data = [
        loop_variable: loop_variable,
        collection_expression: collection_expression,
        content: processed_content
      ]

      block_node = {:loop_block, block_data, []}
      {:ok, {block_node, rest}}
    end
  end

  defp collect_loop_block([node | rest], loop_variable, collection_expression, content, depth) do
    # Regular node - add to loop content
    collect_loop_block(rest, loop_variable, collection_expression, [node | content], depth)
  end

  # State management helpers for conditional block collection

  defp save_current_branch_content(%ConditionalBlockState{} = state) do
    reversed_content = Enum.reverse(state.current_content)

    case state.current_branch do
      :if ->
        %{state | if_content: state.if_content ++ reversed_content, current_content: []}

      {:elsif, _condition} ->
        updated_elsif_branches =
          List.update_at(state.elsif_branches, -1, fn {cond, content} ->
            {cond, content ++ reversed_content}
          end)

        %{state | elsif_branches: updated_elsif_branches, current_content: []}

      :else ->
        %{state | else_content: reversed_content, current_content: []}
    end
  end

  defp add_elsif_branch(%ConditionalBlockState{} = state, condition) do
    new_elsif_branches = state.elsif_branches ++ [{condition, []}]
    %{state | elsif_branches: new_elsif_branches, current_branch: {:elsif, condition}}
  end

  defp switch_to_else_branch(%ConditionalBlockState{} = state) do
    %{state | current_branch: :else}
  end

  defp add_node_to_current_content(%ConditionalBlockState{} = state, node) do
    %{state | current_content: [node | state.current_content]}
  end

  # Helper to recursively process elsif branches content
  defp process_elsif_branches(elsif_branches) do
    Enum.map(elsif_branches, fn {condition, content} ->
      {condition, process_blocks(content)}
    end)
  end
end
