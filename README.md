# ExUnitParameterize
![tests](https://github.com/rciorba/yapara/actions/workflows/test.yaml/badge.svg?branch=master)

Parameterized tests for ExUnit.

Examples:

```elixir
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

```

## Test naming

By default the string representation of the params will be appended to the test name, unless you
provide an explicit name.

For the example above the test names would be:
  * basic test[a: 1, b: 1, expected: 2]
  * basic test[one_plus_two]
  * basic test[failing_case]

In case the name would be longer than the max atom size, the 1-based index will be used.

### Note on spelling
Unfortunately, parameterize has many spellings, and there's no one single
"correct" one. I've picked parameterize over parameterise, parametrize or parametrise, simply
because it seems to be slightly more popular globally.

## Installation

ExUnitParameterize can be installed by adding `ex_unit_parameterize` to your list of dependencies in `mix.exs`:

```elixir
def deps do
  [
    {:ex_unit_parameterize, "~> 0.1.0"}
  ]
end
```

The docs can be found at [https://hexdocs.pm/ex_unit_parameterize](https://hexdocs.pm/ex_unit_parameterize).
