defmodule ParameterizeTest do
  use ExUnit.Case
  doctest Parameterize

  import ExUnit.CaptureIO

  test "parametrized test" do
    defmodule SampleTest do
      use ExUnit.Case
      import Parameterize

      parametrized_test "basic test", [
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

  test "generated names" do
    defmodule SampleTest do
      use ExUnit.Case
      import Parameterize
      parametrized_test "name", [
        [a: 1, b: "2"],
        {:explicit_id, [a: 1, b: "2"]},
        [a: 1, b: [c: 2, d: 3], c: %{e: "f"}],
        [long: "qwertyuiopasdfghjklzxcvbnmqwertyuiopasdfghjklzxcvbnmqwertyuiopasdfghjklzxcvbnmqwertyuiopasdfghjklzxcvbnmqwertyuiopasdfghjklzxcvbnmqwertyuiopasdfghjklzxcvbnmqwertyuiopasdfghjklzxcvbnmqwertyuiopasdfghjklzxcvbnmqwertyuiopasdfghjklzxcvbnmqwertyuiopasdfghjklzxcvbnmqwertyuiopasdfghjklzxcvbnmqwertyuiopasdfghjklzxcvbnmqwertyuiopasdfghjklzxcvbnm"],
      ] do
        assert true
      end

    end

    ExUnit.Server.modules_loaded()
    configure_and_reload_on_exit(colors: [enabled: false])

    output = capture_io(fn ->
      predictable_ex_unit_start([trace: true])
      assert ExUnit.run() == %{failures: 0, skipped: 0, total: 4, excluded: 0}
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

  test "error reporting" do
    defmodule SampleTest do
      use ExUnit.Case
      import Parameterize
      parametrized_test "name", [
        [a: 1, b: 2],
      ] do
        assert a * a == b
      end

    end

    ExUnit.Server.modules_loaded()
    configure_and_reload_on_exit(colors: [enabled: false])

    output = capture_io(fn ->
      predictable_ex_unit_start([trace: true])
      # ExUnit.run()
      assert ExUnit.run() == %{failures: 1, skipped: 0, total: 1, excluded: 0}
    end)
    [
      ~s<test/parameterize_test.exs:71:>,  # line number reported
      ~s<assert a * a == b>,  # the assertion is included
    ]
    |> Enum.map(fn line ->
      assert output  =~ line
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
