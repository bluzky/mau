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
    collect_conditional_block(nodes, if_condition, if_content, elsif_branches, else_content, [], :if)
  end

  defp collect_conditional_block(
         [],
         _if_condition,
         _if_content,
         _elsif_branches,
         _else_content,
         _current_content,
         _current_tag
       ) do
    {:error, "Unclosed if statement - missing endif"}
  end

  defp collect_conditional_block(
         [{:tag, [:elsif, condition], _opts} | rest],
         if_condition,
         if_content,
         elsif_branches,
         else_content,
         current_content,
         current_tag
       ) do
    # Save current_content to the appropriate branch based on current_tag
    {updated_if_content, updated_elsif_branches, _} =
      save_current_content(if_content, elsif_branches, current_content, current_tag)

    # Add new elsif branch and switch to it
    new_elsif_branches = updated_elsif_branches ++ [{condition, []}]

    collect_conditional_block(
      rest,
      if_condition,
      updated_if_content,
      new_elsif_branches,
      else_content,
      [],
      {:elsif, condition}
    )
  end

  defp collect_conditional_block(
         [{:tag, [:else], _opts} | rest],
         if_condition,
         if_content,
         elsif_branches,
         else_content,
         current_content,
         current_tag
       ) do
    # Save current_content to the appropriate branch based on current_tag
    {updated_if_content, updated_elsif_branches, _} =
      save_current_content(if_content, elsif_branches, current_content, current_tag)

    # Switch to else phase
    collect_conditional_block(
      rest,
      if_condition,
      updated_if_content,
      updated_elsif_branches,
      else_content,
      [],
      :else
    )
  end

  defp collect_conditional_block(
         [{:tag, [:endif], _opts} | rest],
         if_condition,
         if_content,
         elsif_branches,
         _else_content,
         current_content,
         current_tag
       ) do
    # Save current_content to the appropriate branch based on current_tag
    {final_if_content, final_elsif_branches, final_else_content} =
      save_current_content(if_content, elsif_branches, current_content, current_tag)

    # Build the conditional block node
    final_else_branch =
      if final_else_content != nil and final_else_content != [],
        do: process_blocks(final_else_content),
        else: nil

    block_data = [
      if_branch: {if_condition, process_blocks(final_if_content)},
      elsif_branches: process_elsif_branches(final_elsif_branches),
      else_branch: final_else_branch
    ]

    block_node = {:conditional_block, block_data, []}
    {:ok, {block_node, rest}}
  end

  defp collect_conditional_block(
         [{:tag, [:if, nested_condition], _nested_opts} | rest],
         if_condition,
         if_content,
         elsif_branches,
         else_content,
         current_content,
         current_tag
       ) do
    # Found nested if - recursively process it as a complete conditional block
    case collect_conditional_block(rest, nested_condition, [], [], nil) do
      {:ok, {nested_block, remaining_nodes}} ->
        # Add the processed nested block to current content
        collect_conditional_block(
          remaining_nodes,
          if_condition,
          if_content,
          elsif_branches,
          else_content,
          [nested_block | current_content],
          current_tag
        )

      {:error, error} ->
        {:error, error}
    end
  end

  defp collect_conditional_block(
         [node | rest],
         if_condition,
         if_content,
         elsif_branches,
         else_content,
         current_content,
         current_tag
       ) do
    # Regular node - add to current content
    collect_conditional_block(rest, if_condition, if_content, elsif_branches, else_content, [
      node | current_content
    ], current_tag)
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

  # Helper to save current_content to the appropriate branch based on current_tag
  defp save_current_content(if_content, elsif_branches, current_content, current_tag) do
    case current_tag do
      :if ->
        # Current content belongs to if branch
        updated_if_content = if_content ++ Enum.reverse(current_content)
        {updated_if_content, elsif_branches, nil}

      {:elsif, _} ->
        # Current content belongs to last elsif branch
        updated_elsif_branches =
          List.update_at(elsif_branches, -1, fn {cond, content} ->
            {cond, content ++ Enum.reverse(current_content)}
          end)

        {if_content, updated_elsif_branches, nil}

      :else ->
        # Current content is else content
        {if_content, elsif_branches, Enum.reverse(current_content)}
    end
  end

  # Helper to recursively process elsif branches content
  defp process_elsif_branches(elsif_branches) do
    Enum.map(elsif_branches, fn {condition, content} ->
      {condition, process_blocks(content)}
    end)
  end
end
