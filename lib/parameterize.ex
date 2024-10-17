defmodule ExUnitParameterize do
  @moduledoc """
  Parameterized tests for ExUnit.

  Provides the `parameterized_test` macro, implementing test parameterization for ExUnit.

  The `parameterized_test` macro relies on the `ExUnit.Case.test` macro, and should support
  all the same use-cases.
  Please file an issue if you find use-cases of test which parameterized_test doesn't handle.


  ## Examples:

      defmodule ParameterizedTest do
        use ExUnit.Case
        import ExUnitParameterize

        parameterized_test "basic test", [
          [a: 1, b: 1, expected: 2],                # basic test[a:1, b:1, expected:2]
          one_plus_two: [a: 1, b: 2, expected: 3],  # basic test[one_plus_two]
          failing_case: [a: 1, b: 2, expected: 4]   # basic test[failing_case]
        ] do
          assert a + b == expected
        end
      end

  ## Test naming

  By default the string representation of the params will be appended to the test name,
  unless you provide an explicit name.

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

    # TODO: it would be nice to not write AST by hand and instead use the
    # macro feature to generate the assignments block
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

  # Get or generate the id for a given parameter.
  defp get_or_make_test_id({id, values}), do: {"[#{id}]", values}
  defp get_or_make_test_id(values), do: {Macro.to_string(values), values}

  defp make_name(base_name, id, index) do
    name = "#{base_name}#{id}"

    if byte_size(name) > 255 do
      "#{base_name}[#{index}]"
    else
      name
    end
  end

  # Transform alternate parameter list format to keyword list.
  defp to_keywordlist(vars, values) do
    to_keywordlist(vars, values, [])
  end

  defp to_keywordlist([var | vars], [val | values], accumulator) do
    to_keywordlist(vars, values, [{var, val} | accumulator])
  end

  defp to_keywordlist(vars, values, accumulator) do
    cond do
      vars != [] ->
        raise "vars is longer than values: `#{vars}`"

      values != [] ->
        raise "values is longer than vars: `#{values}`"

      true ->
        accumulator
    end
  end

  defp maybe_extract_var_names([]), do: {nil, []}

  defp maybe_extract_var_names([params_or_var_names | tail]) do
    case params_or_var_names do
      [var_name | _] when is_atom(var_name) ->
        {params_or_var_names, tail}

      _ ->
        {nil, [params_or_var_names | tail]}
    end
  end

  @doc """
  Defines a parameterized test that uses the test context.

  See `ExUnit.Case.test/3` and [ExUnit.Case#module-context](`m:ExUnit.Case#module-context`)

  ## Examples:

      defmodule ParameterizedCaseWithTagsAndContext do
        use ExUnit.Case
        import ExUnitParameterize

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
  defmacro parameterized_test(
             message,
             var \\ quote(do: _),
             parameters,
             contents
           )
           when is_list(parameters) do
    {var_names, parameters} = maybe_extract_var_names(parameters)

    for {param, index} <- Enum.with_index(parameters, 1) do
      {id, values} = get_or_make_test_id(param)
      message = make_name(message, id, index)

      values =
        case var_names do
          nil -> values
          _ -> to_keywordlist(var_names, values)
        end

      contents = inject_assigns(values, contents, line: __CALLER__.line)

      ast =
        quote do
          test unquote(message), unquote(var) do
            unquote(contents)
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
        import ExUnitParameterize
        parameterized_test "name", [
          [a: 1],
          [a: 2],
        ]
      end
  """
  defmacro parameterized_test(message, parameters) do
    {_vars, parameters} = maybe_extract_var_names(parameters)

    for {param, index} <- Enum.with_index(parameters) do
      {id, _values} = get_or_make_test_id(param)
      message = make_name(message, id, index)

      quote do
        test(unquote(message))
      end
    end
  end
end
