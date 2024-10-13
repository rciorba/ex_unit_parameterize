defmodule ParameterizeTest do
  use ExUnit.Case
  doctest ExUnitParameterize

  import ExUnit.CaptureIO

  setup do
    # "run" any registered tests, so state doesn't "leak" between tests.
    # If a test defines a test-module and raises before running it, the next test
    # will not have a clean slate.
    capture_io(fn -> ExUnit.run() end)
    :ok
  end

  test "parameterized test, keywordlist interface" do
    defmodule KeywordListInterface do
      use ExUnit.Case
      import ExUnitParameterize

      parameterized_test "basic test", [
        [a: 1, b: 2, expected: 3],
        [a: 1, b: 2, expected: 4]
      ] do
        assert a + b == expected
      end
    end

    ExUnit.Server.modules_loaded(false)
    configure_and_reload_on_exit(colors: [enabled: false])

    output =
      capture_io(fn ->
        predictable_ex_unit_start(trace: true)
        assert ExUnit.run() == %{failures: 1, skipped: 0, total: 2, excluded: 0}
      end)

    assert output =~ "\n2 tests, 1 failure\n"
  end

  test "parameterized test, alternate interface" do
    defmodule AlternateInterface do
      use ExUnit.Case
      import ExUnitParameterize

      parameterized_test(
        "basic test",
        [
          [:a, :b, :expected],
          [1, 2, 3],
          [1, 2, 4]
        ]
      ) do
        assert a + b == expected
      end
    end

    ExUnit.Server.modules_loaded(false)
    configure_and_reload_on_exit(colors: [enabled: false])

    output =
      capture_io(fn ->
        predictable_ex_unit_start(trace: true)
        assert ExUnit.run() == %{failures: 1, skipped: 0, total: 2, excluded: 0}
      end)

    assert output =~ "\n2 tests, 1 failure\n"
  end

  test "keywordlist interface with context" do
    defmodule WithContext do
      use ExUnit.Case
      import ExUnitParameterize

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

    io =
      capture_io(fn ->
        predictable_ex_unit_start(trace: true)
        assert ExUnit.run() == %{failures: 1, skipped: 0, total: 2, excluded: 0}
      end)

    assert io =~ "\n2 tests, 1 failure\n"
  end

  test "alternate interface parameterized test with context" do
    defmodule AlternateInterfaceWithContext do
      use ExUnit.Case
      import ExUnitParameterize

      setup do
        {:ok, spam: "spam"}
      end

      parameterized_test "basic test with context", context, [
        [:a, :b, :expected],
        [1, 2, 3],
        [1, 2, 4]
      ] do
        assert context[:spam] == "spam"
        assert a + b == expected
      end
    end

    ExUnit.Server.modules_loaded(false)
    configure_and_reload_on_exit(colors: [enabled: false])

    io =
      capture_io(fn ->
        predictable_ex_unit_start(trace: true)
        assert ExUnit.run() == %{failures: 1, skipped: 0, total: 2, excluded: 0}
      end)

    assert io =~ "\n2 tests, 1 failure\n"
  end

  test "tags with explicit context, keywordlist interface" do
    defmodule KeywordlistInterfaceWithTagsAndContext do
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

    ExUnit.Server.modules_loaded(false)
    configure_and_reload_on_exit(colors: [enabled: false])

    assert capture_io(fn ->
             predictable_ex_unit_start(trace: true)
             assert ExUnit.run() == %{failures: 1, skipped: 0, total: 2, excluded: 0}
           end) =~ "\n2 tests, 1 failure\n"
  end

  test "tags with explicit context, alternate interface" do
    defmodule AlternateInterfaceWithTagsAndContext do
      use ExUnit.Case
      import ExUnitParameterize

      setup do
        {:ok, spam: "spam"}
      end

      @tag foo_tag: "foo"
      @tag :bar_tag
      parameterized_test "basic test with tags and context", context, [
        [:a, :b, :expected],
        [1, 2, 3],
        [1, 2, 4]
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

  test "tags with setup and no context, keywordlist interface" do
    defmodule KeywordlistInterfaceWithSetupAndNoContext do
      use ExUnit.Case
      import ExUnitParameterize

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

  test "tags with setup and no context, alternate interface" do
    defmodule AlternateInterfaceWithSetupAndNoContext do
      use ExUnit.Case
      import ExUnitParameterize

      setup context do
        assert context[:foo_tag] == "foo"
        context
      end

      @tag foo_tag: "foo"
      @tag :bar_tag
      parameterized_test "test with tags", [
        [:a, :b, :expected],
        [1, 2, 3],
        [1, 2, 4]
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

  test "not implemented, keywordlist interface" do
    defmodule KeywordlistInterfaceNotImplemented do
      use ExUnit.Case
      import ExUnitParameterize

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

  test "not implemented, alternate interface" do
    defmodule AlternateInterfaceNotImplemented do
      use ExUnit.Case
      import ExUnitParameterize

      parameterized_test("name", [
        [:a],
        [1],
        [2]
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
      ~s<* test name[1]>,
      ~s<* test name[2]>
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
        import ExUnitParameterize  # line: 3
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
      # line number correctly reported
      ~s<test/parameterize_test.exs:7:>,
      # the assertion is included
      ~s<assert a * a == b>
    ]
    |> Enum.map(fn line ->
      assert output =~ line
    end)
  end

  test "wrong invocation" do
    sut = fn ->
      renumber_lines(
        defmodule WrongInvocationCase do
          use ExUnit.Case
          import ExUnitParameterize

          parameterized_test "name", %{
            "bad" => [a: 1, b: 2]
          } do
            assert a * a == b
          end
        end
      )
    end

    assert_raise(FunctionClauseError, ~r/no function clause matching in ExUnitParameterize/, sut)
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
