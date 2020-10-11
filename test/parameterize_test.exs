defmodule ParameterizeTest do
  use ExUnit.Case
  doctest Parameterize

  import ExUnit.CaptureIO

  test "parameterized test" do
    defmodule SampleTest do
      use ExUnit.Case
      import Parameterize

      parameterized_test "basic test", [
        [a: 1, b: 2, expected: 3],
        [a: 1, b: 2, expected: 4]
      ] do
        assert a + b == expected
      end

    end

    ExUnit.Server.modules_loaded()
    configure_and_reload_on_exit(colors: [enabled: false])

    assert capture_io(fn ->
      predictable_ex_unit_start([trace: true])
      assert ExUnit.run() == %{failures: 1, skipped: 0, total: 2, excluded: 0}
    end) =~ "\n2 tests, 1 failure\n"
  end

  test "parameterized test with context" do
    defmodule SampleTest do
      use ExUnit.Case
      import Parameterize

      setup do
        {:ok, spam: "spam", ham: "ham"}
      end

      parameterized_test "basic test with context", %{spam: spam_value} = context, [
        [a: 1, b: 2, expected: 3],
        [a: 1, b: 2, expected: 4]
      ] do
        assert spam_value == "spam"
        assert context[:ham] == "ham"
        assert a + b == expected
      end

    end

    ExUnit.Server.modules_loaded()
    configure_and_reload_on_exit(colors: [enabled: false])

    assert capture_io(fn ->
      predictable_ex_unit_start([trace: true])
      assert ExUnit.run() == %{failures: 1, skipped: 0, total: 2, excluded: 0}
    end) =~ "\n2 tests, 1 failure\n"
  end

  test "generated names" do
    defmodule SampleTest do
      use ExUnit.Case
      import Parameterize
      parameterized_test "name", [
        [a: 1, b: "2"],
        {:explicit_id, [a: 1, b: "2"]},
        [a: 1, b: [c: 2, d: 3], c: %{e: "f"}],
        [long: "qwertyuiopasdfghjklzxcvbnmqwertyuiopasdfghjklzxcvbnmqwertyuiopasdfghjklzxcvbnmqwertyuiopasdfghjklzxcvbnmqwertyuiopasdfghjklzxcvbnmqwertyuiopasdfghjklzxcvbnmqwertyuiopasdfghjklzxcvbnmqwertyuiopasdfghjklzxcvbnmqwertyuiopasdfghjklzxcvbnmqwertyuiopasdfghjklzxcvbnmqwertyuiopasdfghjklzxcvbnmqwertyuiopasdfghjklzxcvbnmqwertyuiopasdfghjklzxcvbnm"],
        explicit_id2: [a: 1],
      ] do
        assert true
      end

    end

    ExUnit.Server.modules_loaded()
    configure_and_reload_on_exit(colors: [enabled: false])

    output = capture_io(fn ->
      predictable_ex_unit_start([trace: true])
      assert ExUnit.run() == %{failures: 0, skipped: 0, total: 5, excluded: 0}
    end)
    [
      ~s<* test name[a: 1, b: "2"]>,
      ~s<* test name[explicit_id]>,
      ~s<* test name[a: 1, b: [c: 2, d: 3], c: %{e: "f"}]>,
      ~s<* test name[4]>,
    ]
    |> Enum.map(fn name ->
      assert output  =~ name
    end)
  end

  defp fix_line_number({op, meta, operands}, delta) do
    line_number = Keyword.get(meta, :line, nil)
    case line_number do
      nil -> {op, meta, operands}
      _ ->
        meta = Keyword.put(meta, :line, line_number + delta)
        {op, meta, operands}
    end
  end

  defp fix_line_number(node, delta) do
    node
  end

  defp get_linum_delta({_, meta, _}) do
    1 - Keyword.get(meta, :line, 1)
  end

  defmacro renumber_lines(quoted) do
    delta = get_linum_delta(quoted)
    fix_linum_fn = fn (node) ->
      fix_line_number(node, delta)
    end
    Macro.postwalk(quoted, fix_linum_fn)
  end

  test "error reporting and line numbers" do
    renumber_lines(
      defmodule SampleTest do  # line: 1
        use ExUnit.Case  # line: 2
        import Parameterize  # line: 3
        parameterized_test "name", [  # line: 4
          [a: 1, b: 2],  # line: 5
        ] do  # line: 6
          assert a * a == b  # line: 7
        end  # line: 8
      end  # line: 9
    )

    ExUnit.Server.modules_loaded()
    configure_and_reload_on_exit(colors: [enabled: false])

    output = capture_io(fn ->
      predictable_ex_unit_start([trace: true])
      assert ExUnit.run() == %{failures: 1, skipped: 0, total: 1, excluded: 0}
    end)
    [
      ~s<test/parameterize_test.exs:7:>,  # line number correctly reported
      ~s<assert a * a == b>,  # the assertion is included
    ]
    |> Enum.map(fn line ->
      assert output  =~ line
    end)
  end

  test "wrong invocation" do
    output = capture_io(fn ->
      assert_raise FunctionClauseError, "no function clause matching in Parameterize.parameterized_test/4", fn ->
        renumber_lines(
          defmodule SampleTest do
            use ExUnit.Case
            import Parameterize
            parameterized_test "name", %{  # map's aren't supported, we should have a kw list
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
