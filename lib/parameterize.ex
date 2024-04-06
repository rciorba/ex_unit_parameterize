defmodule ExUnitParametrize do
  @moduledoc """
  Parameterized tests for ExUnit.

  Provides the `parameterized_test` macro, implementing test parameterization for ExUnit.

  The `parameterized_test` macro relies on the `ExUnit.Case.test` macro, and should support all the same use-cases.
  Please file an issue if you find use-cases of test which parameterized_test doesn't handle.


  ## Examples:

      defmodule ParameterizedTest do
        use ExUnit.Case
        import ExUnitParametrize

        parameterized_test "basic test", [
          [a: 1, b: 1, expected: 2],                # basic test[a:1, b:1, expected:2]
          one_plus_two: [a: 1, b: 2, expected: 3],  # basic test[one_plus_two]
          failing_case: [a: 1, b: 2, expected: 4]   # basic test[failing_case]
        ] do
          assert a + b == expected
        end
      end

  ## Test naming

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
      {:__block__, line_info, content} when is_list(content) -> {line_info, content}
      content when is_tuple(content) -> {[], [content]}
    end
  end

  defp prepend_to_content(prefix, content, line_info) do
    {:__block__, line_info, prefix ++ content}
  end

  defp make_assigns_block(values, line_info) do
    line_num = Keyword.get(line_info, :line, 1)
    values
    |> Enum.map(fn {key, val} ->
      {:=, [line: line_num], [{key, [line: line_num], nil}, val]}
    end)
  end

  defp inject_assigns(values_map, block, line_info) do
    {_block_line_info, content} =
      block
      |> drop_do
      |> extract_test_content

    prepend_to_content(make_assigns_block(values_map, line_info), content, line_info)
  end

  defp unpack({id, values}), do: {"[#{id}]", values}

  defp unpack(values) do
    id = Macro.to_string(values)
    {id, values}
  end

  defp make_name(base_name, id, index) do
    name = "#{base_name}#{id}"

    if byte_size(name) > 255 do
      "#{base_name}[#{index}]"
    else
      name
    end
  end

  @doc """
  Defines a parameterized test.

  See `ExUnit.Case.test/3`.

  ## Examples:

      defmodule ParameterizedCase do
        use ExUnit.Case
        import ExUnitParametrize

        parameterized_test "basic test", [
          [a: 1, b: 2, expected: 3],
          [a: 1, b: 2, expected: 4]
        ] do
          assert a + b == expected
        end

      end
  """
  defmacro parameterized_test(name, parameters, block) do
    quote do
      parameterized_test(unquote(name), _, unquote(parameters), unquote(block))
    end
  end

  @doc """
  Defines a parameterized test that uses the test context.

  See `ExUnit.Case.test/3` and [ExUnit.Case#module-context](`m:ExUnit.Case#module-context`)

  ## Examples:

      defmodule ParameterizedCaseWithTagsAndContext do
        use ExUnit.Case
        import ExUnitParametrize

        setup do
          {:ok, spam: "spam"}
        end

        @tag foo_tag: "foo"
        @tag :bar_tag
        parameterized_test "basic test with tags and context", context, [
          [a: 1, b: 2, expected: 3],
          [a: 1, b: 2, expected: 4]
        ] do
          assert context[:foo_tag] == "foo"
          assert context[:bar_tag] == true
          assert context[:spam] == "spam"
          assert a + b == expected
        end

      end
  """
  defmacro parameterized_test(name, context, parameters, block) when is_list(parameters) do
    for {param, index} <- Enum.with_index(parameters, 1) do
      {id, values} = unpack(param)
      name = make_name(name, id, index)
      block = inject_assigns(values, block, line: __CALLER__.line)

      ast =
        quote do
          test unquote(name), unquote(context) do
            unquote(block)
          end
        end

      ast
    end
  end

  @doc """
  Defines a not implemented parametrized test.

  See `ExUnit.Case.test/1`.

  ## Examples:

      defmodule NotImplementedCase do
        use ExUnit.Case
        import ExUnitParametrize
        parameterized_test "name", [
          [a: 1],
          [a: 2],
        ]
      end
  """
  defmacro parameterized_test(name, parameters) do
    for {param, index} <- Enum.with_index(parameters) do
      {id, _values} = unpack(param)
      name = make_name(name, id, index)

      quote do
        test(unquote(name))
      end
    end
  end
end
