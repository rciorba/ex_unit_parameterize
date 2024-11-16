# ExUnitParameterize
![tests](https://github.com/rciorba/yapara/actions/workflows/test.yaml/badge.svg?branch=master)
[![](https://img.shields.io/hexpm/v/ex_unit_parameterize.svg?style=flat)](https://hex.pm/packages/ex_unit_parameterize)

Parameterized tests for ExUnit.

Provides the `parameterized_test` macro, implementing test parameterization for
ExUnit. This aims to behave just like the `ExUnit.test` macro (it actually uses the test
macro, under the hood), but takes one extra argument, the list of parameters.

Each group of parameters in the list will generate a test.
Parameters will get injected into the test's `do` block as variables.
There are two ways to specify the names of the variables:
 * once for all the params, as a list of atoms
 * repeated for each group of params, by passing each params group as a keywords list

Example:

```elixir
defmodule ParameterizedTest do
  use ExUnit.Case
  import ExUnitParameterize

  # specify the var names once, then provide the parameters
  parameterized_test "vars once", [
    [:a, :b, :expected],
    [1, 1, 2],                # vars once[a:1, b:1, expected:2]
    one_plus_two: [1, 2, 3],  # vars once[one_plus_two]
    failing_case: [1, 2, 4]   # vars once[failing_case]
  ] do
    assert a + b == expected
  end

  # repeat the var names for each param group
  parameterized_test "vars repeated", [
    [a: 1, b: 1, expected: 2],                # vars repeated[a:1, b:1, expected:2]
    one_plus_two: [a: 1, b: 2, expected: 3],  # vars repeated[one_plus_two]
    failing_case: [a: 1, b: 2, expected: 4]   # vars repeated[failing_case]
  ] do
    assert a + b == expected
  end
end

```

## Test naming

By default the string representation of the params will be appended to the test name,
but you can provide an explicit name by passing the group of parameters as a keyword list.

For the example above the names for the `vars once` parameterized\_test would be:
  * `vars once[a: 1, b: 1, expected: 2]`
  * `vars once[one_plus_two]`
  * `vars once[failing_case]`

In case the name would be longer than the max atom size, the 1-based index will be used.

### Note on spelling
Unfortunately, parameterize has many spellings, and there's no single "correct" one.
I've picked parameterize over parameterise, parametrize or parametrise, simply
because it seems to be slightly more popular globally.

## Installation

ExUnitParameterize can be installed by adding `ex_unit_parameterize` to your list of
dependencies in `mix.exs`:

```elixir
def deps do
  [
    {:ex_unit_parameterize, "~> 0.1.0"}
  ]
end
```

The docs can be found at [https://hexdocs.pm/ex_unit_parameterize](https://hexdocs.pm/ex_unit_parameterize).
