defmodule Mau.Budget do
  @moduledoc false

  # Totals shared by one whole render. `:counters` is mutable, so this works
  # through read-only opts and through directives, which return plain values.

  @iterations 1
  @output 2

  @default_max_loop_iterations 10_000
  @default_max_total_iterations 1_000_000
  @default_max_output_size 10_000_000

  def ensure(opts) do
    if opts[:budget], do: opts, else: Keyword.put(opts, :budget, :counters.new(2, []))
  end

  @doc """
  Spends `count` iterations for one loop, checking both loop limits.
  """
  def spend_iterations(count, opts) do
    max_loop = opts[:max_loop_iterations] || @default_max_loop_iterations
    max_total = opts[:max_total_iterations] || @default_max_total_iterations

    cond do
      count > max_loop ->
        {:error,
         Mau.Error.limit_error("Loop iteration count #{count} exceeds maximum #{max_loop}")}

      (total = spend(opts[:budget], @iterations, count)) > max_total ->
        {:error,
         Mau.Error.limit_error("Total iteration count #{total} exceeds maximum #{max_total}")}

      true ->
        :ok
    end
  end

  @doc """
  Spends output bytes against the total for the render.
  """
  def spend_output(size, opts) do
    check_size(spend(opts[:budget], @output, size), "Total output size", opts)
  end

  @doc """
  Checks a value being built, which may never reach the output.
  """
  def check_value(value, opts) when is_binary(value) do
    check_size(byte_size(value), "String size", opts)
  end

  def check_value(_value, _opts), do: :ok

  @doc """
  Checks the expanded size of a list built by a template. Nesting a list inside
  itself shares memory, so it can double in size per step until something expands
  it. Counting stops at the limit, so this can't be exponential itself.
  """
  def check_collection(list, opts) do
    max_size = opts[:max_total_iterations] || @default_max_total_iterations

    if count_items(list, 0, max_size) > max_size do
      {:error, Mau.Error.limit_error("Collection size exceeds maximum #{max_size}")}
    else
      :ok
    end
  end

  defp count_items(_value, count, max_size) when count > max_size, do: count

  defp count_items([head | tail], count, max_size) do
    count_items(tail, count_items(head, count + 1, max_size), max_size)
  end

  defp count_items(_value, count, _max_size), do: count

  defp spend(nil, _index, _amount), do: 0

  defp spend(budget, index, amount) do
    :counters.add(budget, index, amount)
    :counters.get(budget, index)
  end

  defp check_size(size, label, opts) do
    max_size = opts[:max_output_size] || @default_max_output_size

    if size > max_size do
      {:error, Mau.Error.limit_error("#{label} #{size} exceeds maximum #{max_size} bytes")}
    else
      :ok
    end
  end
end
