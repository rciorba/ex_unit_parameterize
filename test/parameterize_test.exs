defmodule ParameterizeTest do
  use ExUnit.Case
  doctest ExUnitParametrize

  import ExUnit.CaptureIO

  test "parameterized test" do
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

    ExUnit.Server.modules_loaded(false)
    configure_and_reload_on_exit(colors: [enabled: false])

    assert capture_io(fn ->
             predictable_ex_unit_start(trace: true)
             assert ExUnit.run() == %{failures: 1, skipped: 0, total: 2, excluded: 0}
           end) =~ "\n2 tests, 1 failure\n"
  end

  test "parameterized test with context" do
    defmodule ParameterizedCaseWithContext do
      use ExUnit.Case
      import ExUnitParametrize

      setup do
        {:ok, spam: "spam"}
      end

      parameterized_test "basic test with context", context, [
        [a: 1, b: 2, expected: 3],
        [a: 1, b: 2, expected: 4]
      ] do
        assert context[:spam] == "spam"
        assert a + b == expected
      end
    end

    ExUnit.Server.modules_loaded(false)
    configure_and_reload_on_exit(colors: [enabled: false])

    assert capture_io(fn ->
             predictable_ex_unit_start(trace: true)
             assert ExUnit.run() == %{failures: 1, skipped: 0, total: 2, excluded: 0}
           end) =~ "\n2 tests, 1 failure\n"
  end

  test "tags with explicit context" do
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

    ExUnit.Server.modules_loaded(false)
    configure_and_reload_on_exit(colors: [enabled: false])

    assert capture_io(fn ->
             predictable_ex_unit_start(trace: true)
             assert ExUnit.run() == %{failures: 1, skipped: 0, total: 2, excluded: 0}
           end) =~ "\n2 tests, 1 failure\n"
  end

  test "tags with setup and no context" do
    defmodule ParameterizedCaseWithTags do
      use ExUnit.Case
      import ExUnitParametrize

      setup context do
        assert context[:foo_tag] == "foo"
        context
      end

      @tag foo_tag: "foo"
      @tag :bar_tag
      parameterized_test "test with tags", [
        [a: 1, b: 2, expected: 3],
        [a: 1, b: 2, expected: 4]
      ] do
        assert a + b == expected
      end
    end

    ExUnit.Server.modules_loaded(false)
    configure_and_reload_on_exit(colors: [enabled: false])

    assert capture_io(fn ->
             predictable_ex_unit_start(trace: true)
             assert ExUnit.run() == %{failures: 1, skipped: 0, total: 2, excluded: 0}
           end) =~ "\n2 tests, 1 failure\n"
  end

  test "not implemented" do
    defmodule NotImplementedCase do
      use ExUnit.Case
      import ExUnitParametrize

      parameterized_test("name", [
        [a: 1],
        [a: 2]
      ])
    end

    ExUnit.Server.modules_loaded(false)
    configure_and_reload_on_exit(colors: [enabled: false])

    output =
      capture_io(fn ->
        predictable_ex_unit_start(trace: true)
        assert ExUnit.run() == %{failures: 2, skipped: 0, total: 2, excluded: 0}
      end)

    [
      ~s<* test name[a: 1]>,
      ~s<* test name[a: 2]>
    ]
    |> Enum.map(fn name ->
      assert output =~ name
    end)
  end

  defp fix_line_number({op, meta, operands}, delta) do
    line_number = Keyword.get(meta, :line, nil)

    case line_number do
      nil ->
        {op, meta, operands}

      _ ->
        meta = Keyword.put(meta, :line, line_number + delta)
        {op, meta, operands}
    end
  end

  defp fix_line_number(node, _delta) do
    node
  end

  defp get_linum_delta({_, meta, _}) do
    1 - Keyword.get(meta, :line, 1)
  end

  defmacrop renumber_lines(quoted) do
    # Rewrite line numbers for modules defines within the tests
    # since we assert on test output including line numbers.

    # If we don't use this line number expected in assertions change when
    # we add/change unrelated tests.
    delta = get_linum_delta(quoted)

    fix_linum_fn = fn node ->
      fix_line_number(node, delta)
    end

    Macro.postwalk(quoted, fix_linum_fn)
  end

  test "error reporting and line numbers" do
    renumber_lines(
      defmodule LineNumbersCase do  # line: 1
        use ExUnit.Case  # line: 2
        import ExUnitParametrize  # line: 3
        parameterized_test "line numbers", [  # line: 4
          [a: 1, b: 2],  # line: 5
        ] do  # line: 6
          assert a * a == b  # line: 7
        end  # line: 8
      end  # line: 9
    )

    ExUnit.Server.modules_loaded(false)
    configure_and_reload_on_exit(colors: [enabled: false])

    output =
      capture_io(fn ->
        predictable_ex_unit_start(trace: true)
        assert ExUnit.run() == %{failures: 1, skipped: 0, total: 1, excluded: 0}
      end)

    [
      ~s<test/parameterize_test.exs:7:>,  # line number correctly reported
      ~s<assert a * a == b>,  # the assertion is included
    ]
    |> Enum.map(fn line ->
      assert output =~ line
    end)
  end

  test "wrong invocation" do
    capture_io(fn ->
      assert_raise FunctionClauseError, "no function clause matching in ExUnitParametrize.parameterized_test/4", fn ->
        renumber_lines(
          defmodule WrongInvocationCase do
            use ExUnit.Case
            import ExUnitParametrize
            parameterized_test "name", %{
              "bad" => [a: 1, b: 2],
            } do
              assert a * a == b
            end
          end
        )
      end
    end)
  end

  defp configure_and_reload_on_exit(opts) do
    old_opts = ExUnit.configuration()
    ExUnit.configure(opts)

    on_exit(fn -> ExUnit.configure(old_opts) end)
  end

  # Runs ExUnit.start/1 with common options needed for predictability
  defp predictable_ex_unit_start(options) do
    ExUnit.start(
      options ++ [autorun: false, seed: 0, colors: [enabled: false], exclude: [:exclude]]
    )
  end
end
