defmodule Parameterize do
  @moduledoc """
  Parameterized tests for ExUnit.

  Implements the parameterized_test macro for usage with ExUnit.

  ## Examples:

      defmodule ParameterizedTest do
        parameterized_test "basic test", [
          [a: 1, b: 1, expected: 2],                # basic test[a:1, b:1, expected:2]
          one_plus_two: [a: 1, b: 2, expected: 3],  # basic test[one_plus_two]
          failing_case: [a: 1, b: 2, expected: 4]   # basic test[failing_case]
        ] do
          assert a + b == expected
        end
      end

  # Test naming

  By default the string representation of the params will be appended to the test name, unless you
  provide an explicit name.

  For the example above the test names would be:
    * basic test[a: 1, b: 1, expected: 2]
    * basic test[one_plus_two]
    * basic test[failing_case]

  In case the name would be longer than the max atom size, the 1-based index will be used.
  """

  require ExUnit.Case

  defp drop_do(block) do
    case block do
      [do: subblock] -> subblock
    end
  end

  defp extract_test_content(block) do
    case block do
      {:__block__, _line_info, content} when is_list(content) -> content
      content when is_tuple(content) -> [content]
    end
  end

  defp prepend_to_content(content, line_info, prefix) do
    {:__block__, line_info, prefix ++ content}
  end

  @doc """
  Take the parameters and generate the variable asignments to inject values in to the parameterized
  test.
  """
  defp make_assigns_block(parameters, line_info) do
    line_num = Keyword.get(line_info, :line, 1)
    parameters
    |> Enum.map(fn {key, val} ->
      {:=, [line: line_num], [{key, [line: line_num], nil}, val]}
    end)
  end

  @doc """
  Prepend variable assignments to code block.
  """
  defp inject_assigns(values_map, block, line_info) do
    block
    |> drop_do
    |> extract_test_content
    |> prepend_to_content(line_info, make_assigns_block(values_map, line_info))
  end

  @doc """
  Generate an id from the string represetation of the values.
  """
  defp unpack_id_and_values(id_and_values_tuple)
  defp unpack_id_and_values({id, values}) do
    {"[#{id}]", values}
  end

  defp unpack_id_and_values(values) do
    id = Macro.to_string(values)
    {id, values}
  end

  @doc """
  Generate a name for the parametrized test.

  If the test name is too long, use numeric index instead of the id.
  """
  defp make_name(base_name, id, index) do
    name = "#{base_name}#{id}"

    if byte_size(name) > 255 do
      "#{base_name}[#{index}]"
    else
      name
    end
  end

  @doc """
  Defines a parametrized test, with context.

  Generates several tests from the parameters list.

  The `var`, will pattern match on the test context. For more information on contexts, see
  `ExUnit.Callbacks`.

  See also `ExUnit.Case.test/3`.

  ## Example:

      parameterized_test "basic test with context", %{spam: spam_value} = context, [
        [a: 1, b: 2, expected: 3],
        [a: 1, b: 2, expected: 4]
      ] do
        assert spam_value == "spam"
        assert context[:ham] == "ham"
        assert a + b == expected
      end

  """
  defmacro parameterized_test(name, var, parameters, block) when is_list(parameters) do
    for {param, index} <- Enum.with_index(parameters, 1) do
      {id, values} = unpack_id_and_values(param)
      name = make_name(name, id, index)
      block = inject_assigns(values, block, [line: __CALLER__.line])

      quote do
        test unquote(name), unquote(var) do
          unquote(block)
        end
      end
    end
  end

  @doc """
  Defines a parameterized test.

  Generates several tests from the parameters list.

  See also `ExUnit.Case.test/3`.

  ## Examples

      parameterized_test "basic test", [
        ok_case: [a: 1, b: 2, expected: 3],
        failing_case: [a: 1, b: 2, expected: 4]
      ] do
        assert a + b == expected
  """
  defmacro parameterized_test(name, parameters, block) do
    quote do
      parameterized_test(unquote(name), _, unquote(parameters), unquote(block))
    end
  end

  @doc """
  Defines not implemented parameterized test.

  These tests will fail as `Not implemented`.

  See also `ExUnit.Case.test/1`.
  """
  defmacro parameterized_test(name, parameters) do
    for {param, index} <- Enum.with_index(parameters) do
      {id, _values} = unpack_id_and_values(param)
      name = make_name(name, id, index)

      quote do
        test(unquote(name))
      end
    end
  end

end
