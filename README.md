# Constants and Enumerated Values for Elixir

This module adds support for a `const` macro that exports single constants
and an `enum` macro that exports enumerated constant values from a module.
These values can be used in guards, match expressions or within normal
expressions, as the macro takes care of expanding the reference to the
constant or enumerated value to its corresponding literal value or function
call, depending on the context where it was used.

## Installation

If [available in Hex](https://hex.pm/docs/publish), the package can be installed
by adding `ex_const` to your list of dependencies in `mix.exs`:

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

The single constants can be accessed just by a nomal function invocation:

    iex> require Settings
    ...> Settings.version
    "1.0"

They can also be use in match expressions that would normally require a
literal value:

    iex> require Settings
    ...> Settings.version = "1.0"
    "1.0"

### Enumerated Values

The enumerated values can also be accessed as a function call:

    iex> require Settings
    ...> Settings.color(:blue)
    255

And can also be used in match expressions or guards:

    iex> require Settings
    ...> import Settings
    ...> value = "AR"
    ...> case value do
    ...>   country_code(:argentina) ->
    ...>     {:ok, "Argentina"}
    ...>   country_code(:italy) ->
    ...>     {:ok, "Italy"}
    ...>   code when code == country_code(:usa) ->
    ...>     {:ok, "United States"}
    ...>   _ ->
    ...>     {:error, {:must_be_one_of, country_codes()}}
    ...> end
    {:ok, "Argentina"}

As the expressions assigned to constants will be resolved at compile-time,
the previous function would be equivalent to the following one:

    iex> value = "AR"
    ...> case value do
    ...>   "AR" -> {:ok, "Argentina"}
    ...>   "IT" -> {:ok, "Italy"}
    ...>   code when code == "US" -> {:ok, "United States"}
    ...>   _ -> {:error, {:must_be_one_of, ["AR", "IT", "US"]}}
    ...> end
    {:ok, "Argentina"}

Sometimes, when an `enum` is referenced in the code, the key to its value is
passed as an expression that cannot be resolved at compile-time. In those
cases the expression will be expanded to a function invocation instead of to
a literal value:

    iex> require Settings
    ...> key = :green
    ...> Settings.color_tuple(key)
    {0, 255, 0}

This works because the `enum` macro adds a function that will act as a
fallback in these cases. The name of the function is that of the `enum`
with the `_enum` string appended to it. For example, for an enum named
`country` the function will be `country_enum/1`. You have to keep this in
mind when you import the module where the `enum` was defined and restrict
the functions that are imported.

