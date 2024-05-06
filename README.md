# Constants and Enumerated Values for Elixir

This module adds support for a `const` macro that exports single constants
and an `enum` macro that exports enumerated constant values from a module.
These values can be used in guards, match expressions or within normal
expressions, as the macro takes care of expanding the reference to the
constant or enumerated value to its corresponding literal value or function
call, depending on the context where it was used.

## Installation

The package can be installed by adding `ex_const` to your list of dependencies
in `mix.exs`:

```elixir
def deps do
  [{:ex_const, "~> 0.1.0"}]
end
```

Documentation can be generated with [ExDoc](https://github.com/elixir-lang/ex_doc)
and published on [HexDocs](https://hexdocs.pm). Once published, the docs can
be found at [https://hexdocs.pm/ex_const](https://hexdocs.pm/ex_const).

## Usage

A module using `const` or `enum` macros can be defined in the following way:

```elixir
defmodule Settings
  use Const
  import Bitwise, only: [bsl: 2]

  @ar "AR"
  @it "IT"
  @us "US"

  const version, do: "1.0"

  const base_path, do: System.cwd()

  const country_codes, do: [@ar, @it, @us]

  enum country_code, do: [argentina: @ar, italy: @it, usa: @us]

  enum color do
    red   bsl(0xff, 16)
    green bsl(0xff, 8)
    blue  bsl(0xff, 0)
  end

  enum color_tuple do
    red   {255, 0, 0}
    green {0, 255, 0}
    blue  {0, 0, 255}
  end
end
```

As you can see, the constants can be assigned both literal values or
expressions that will be resolved at compile-time.

### Single Constants

You can create single constant values by using the `const` macro with the
following syntax:

```elixir
const <name>, do: <value>
```

e.g.

```elixir
const version, do: "1.0"
```

The macro invocation will create and export another macro with the name that
was set in the `const` declaration (e.g. `version/0`) and replace each
reference to it with the value that was assigned to it (e.g. `"1.0"`).

You can use any expression that can be resolved at compile-time as the value
for the `const`.

The single constants can be accessed with a nomal function invocation:

```elixir
require Settings
Settings.version
```

As the reference to the `const` will be replaced by its literal value, you
can even use them in match expressions or in guards. e.g.

```elixir
require Settings
Settings.version = "1.0"
```

### Enumerated Values

You can create enumerated values by using the `enum` macro with the compact
syntax:

```elixir
enum <name>, do: [<key_1>: <value_1>, <key_2>: <value_2>, ...]
```

Or with the expanded syntax:

```elixir
enum <name> do
  <key_1> <value_1>
  <key_2> <value_2>
  [...]
end
```

e.g.

```elixir
enum country_code, do: [argentina: "AR", italy: "IT", usa: "US"]
```

Or:

```elixir
enum country_code do
  argentina "AR"
  italy     "IT"
  usa       "US"
end
```

For each `enum` instance, the macro will create the following additional macros
and functions in the module where it was invoked:

  1. Macro with the name that was assigned to the `enum`. This macro will
     replace every reference to itself with its literal value (if it was called
     with a literal atom as key or was referenced from a match expression) or
     with a call to the fallback function.
  2. Fallback function with a name formed by appending the string `_enum` to
     the name of the `enum` (e.g. `country_code_enum/1`).
  3. Function that will retrieve the key corresponding to a value in the
     `enum`. If there are is more than one key with the same value, the first
     one in the `enum` will be used and the duplicates will be disregarded.

e.g.

```elixir
defmacro country_code(atom) :: String.t
def country_code_enum(atom) :: String.t
def from_country_code(String.t) :: atom
```

The enumerated values can be accessed with a function call:

```elixir
require Settings
Settings.color(:blue)
```

And can also be used in match expressions or guards:

```elixir
require Settings
import Settings
value = "AR"
case value do
  country_code(:argentina) ->
    {:ok, "Argentina"}
  country_code(:italy) ->
    {:ok, "Italy"}
  code when code == country_code(:usa) ->
    {:ok, "United States"}
  _ ->
    {:error, {:must_be_one_of, country_codes()}}
end
```

As the expressions assigned to constants will be resolved at compile-time,
the previous function would be equivalent to the following one:

```elixir
value = "AR"
case value do
  "AR" -> {:ok, "Argentina"}
  "IT" -> {:ok, "Italy"}
  code when code == "US" -> {:ok, "United States"}
  _ -> {:error, {:must_be_one_of, ["AR", "IT", "US"]}}
end
```

Sometimes, when an `enum` is referenced in the code, the key to its value is
passed as an expression that cannot be resolved at compile-time. In those
cases the expression will be expanded to a function invocation instead of to
a literal value:

```elixir
require Settings
key = :green
Settings.color_tuple(key)
```

This works because the macro replaces the reference to itself with a call to
the fallback function. The name of the function is that of the `enum`
with the `_enum` string appended to it. For example, for an enum named
`country` the function will be `country_enum/1`. You have to keep this in
mind when you import the module where the `enum` was defined and restrict
the functions that are imported.
