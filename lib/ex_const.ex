defmodule Const do
  @moduledoc """
  Constants and Enumerated Values for Elixir

  ## Overview

  This module adds support for a `const` macro that exports single constants
  and an `enum` macro that exports enumerated constant values from a module.
  These values can be used in guards, match expressions or within normal
  expressions, as the macro takes care of expanding the reference to the
  constant or enumerated value to its corresponding literal value or function
  call, depending on the context where it was used.

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

  ## Single Constants

  You can create single constant values by using the `const` macro with the
  following syntax:

      const <name>, do: <value>

  e.g.

      const version, do: "1.0"

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

  ## Enumerated Values

  You can create enumerated values by using the `enum` macro with the compact
  syntax:

      enum <name>, do: [<key_1>: <value_1>, <key_2>: <value_2>, ...]

  Or with the expanded syntax:

      enum <name> do
        <key_1> <value_1>
        <key_2> <value_2>
        [...]
      end

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
    3. Function that will retrieve the key corresponding to a value in the `enum`.
       If there are is more than one key with the same value, the first in the
       `enum` will be used and the other ones will be disregarded.

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

  """

  @doc false
  defmacro __using__(_opts) do
    caller_module = __CALLER__.module

    quote do
      import unquote(__MODULE__)

      Module.register_attribute(unquote(caller_module), :consts, accumulate: true)
      Module.register_attribute(unquote(caller_module), :enums, accumulate: true)

      # Add hook for const and enum generation at the end of the code.
      @before_compile {unquote(__MODULE__), :__after_compile__}
    end
  end

  @doc false
  defmacro __after_compile__(env) do
    consts = generate(:consts, &define_const/3, env)
    enums = generate(:enums, &define_enum/3, env)
    # IO.puts("AST for #{env.module}: #{inspect [consts, enums]}")
    [consts, enums]
  end

  defp generate(attr, define, env) do
    env.module
    |> Module.get_attribute(attr)
    |> Enum.reverse()
    |> Enum.map(fn {name, quoted_value} -> define.(name, quoted_value, env) end)
  end

  @doc """
  Defines a macro representing a single constant value that is resolved at
  compile-time and is exported from the module. The macro can be used both in
  match and normal expressions in place of the literal value that was assigned
  to the constant.

  The syntax to define it looks like the following one:
  ```elixir
  const secret_key, do: "AABBCCDDEEFF"
  ```

  Where `secret_key` is the name that will be used to reference the constant
  and `"AABBCCDDEEFF"` is what will be returned by it.

  The constant can be referenced by using the normal macro/function syntax.
  e.g. `Settings.secret_key()`.

  Given that the macro will replace its invocation with the literal value, it
  can be used in a match expressions like the following one:
  ```elixir
  require Settings
  Settings.color(:blue) = 0xff
  ```

  """
  defmacro const(quoted_name, do: quoted_value) do
    name = unescape_var(quoted_name)
    # IO.puts("Accumulating const named '#{name}' for quoted value: #{inspect quoted_value}")
    quote do
      @consts {unquote(name), unquote(Macro.escape(quoted_value))}
    end
  end

  defp define_const(name, quoted_value, env) when is_atom(name) do
    # Define macro to expand non-enumerated constants.
    expr = quote do
      defmacro unquote(name)() do
        # We must escape the evaluated value, as the macro has to return a quoted expression.
        unquote(Macro.escape(eval_quoted_value(name, quoted_value, env)))
      end
    end
    # IO.puts("AST generated for '#{name}' const macro: #{inspect expr}")
    expr
  end

  @doc """
  Defines a macro representing an enumerated value that is resolved at
  compile-time and is exported from the module. The macro can be used both in
  match and normal expressions in place of the literal value that was assigned
  to each value.

  Two syntaxes are supported, the compact and the expanded one, very much like
  most constructs in Elixir. Here's a sample of what it looks like"
  ```elixir
  defmodule Defs
    use Const

    enum stock, do: [apple: "AAPL", facebook: "FB", google: "GOOG"]

    enum file_ext do
      elixir ".ex"
      erlang ".erl"
      go     ".go"
      rust   ".rs"
    end
  end
  ```

  The enumerated values can be referenced by using the normal macro/function
  syntax, passing the key as argument to the macro.
  e.g. 'Config.file_ext(:elixir)'.

  Given that the macro will replace its invocation with the literal value, it
  can be used in a match expressions like the following one:
  ```elixir
  Defs.stock(:google) = "GOOG"
  ```

  """
  defmacro enum(quoted_name, do: quoted_values) do
    name = unescape_var(quoted_name)
    # IO.puts("Accumulating enum named '#{name}' for quoted values: #{inspect quoted_values}")
    quote do
      @enums {unquote(name), unquote(Macro.escape(quoted_values))}
    end
  end

  defp define_enum(name, quoted_values, env) when is_atom(name) do
    # To implement an enumerated constant we have to:
    #
    #   1. Evaluate the expressions assigned to each of them that can be
    #      resolved at compile-time to convert them to literal values.
    #   2. Define a function to be used as fallback when the enum is used in a
    #      context that cannot be resolved at compile-time. The function will be
    #      named after the enum, adding the suffix `_enum` to it.
    #      e.g. for an `enum` named `color` the function will be `color_enum/1`.
    #   3. We also define the macro with the enum's name that will expand every
    #      reference to the enumerated constant to its literal value (if the
    #      reference can be resolved at compile-time) or with a function
    #      invocation (if it has to be resolved at run-time).
    #   4. Define a function that will retrieve the enum key given an assigned
    #      value. The function will be named prepending `from_` to the enum's
    #      name. e.g. for an `enum` named `color` the function will be `from_color/1`.
    #
    # IO.puts("Creating '#{name}' enum for values: #{inspect quoted_values}")
    eval_values = eval_quoted_enum(name, quoted_values, env)
    # IO.puts("Creating '#{name}' enum for evaluated values: #{inspect eval_values}")
    if Keyword.keyword?(eval_values) do
      fun_name = Atom.to_string(name) <> "_enum"
      |> String.to_atom()
      fallback_fun = define_enum_fallback_fun(name, fun_name, eval_values)
      expand_macro = define_enum_expand_macro(name, fun_name, eval_values, env)
      inverse_fun = define_enum_inverse_fun(name, eval_values)
      expr = [fallback_fun, expand_macro, inverse_fun]
      # IO.puts("AST generated for '#{name}' enum macro: #{inspect expr}")
      expr
    else
      raise Const.Error, reason: :assign, name: name
    end
  end

  defp define_enum_fallback_fun(name, fun_name, quoted_values) do
    quoted_fun = for {key, quoted_value} <- quoted_values do
      # IO.puts("Generating fallback function '#{fun_name}' for key '#{key}' with value #{inspect quoted_value}")
      # FIXME: verify that the key and the value are constants
      quote do
        def unquote(fun_name)(unquote(key)) do
          unquote(quoted_value)
        end
      end
    end
    quoted_fun_tail = quote do
      def unquote(fun_name)(key) do
        raise Const.Error, reason: :fetch_key, name: unquote(name), key: unescape_var(key)
      end
    end
    [quoted_fun, quoted_fun_tail]
  end

  defp define_enum_inverse_fun(name, quoted_values) do
    fun_name = "from_" <> Atom.to_string(name)
    |> String.to_atom()
    # Discard duplicated values in the inverse functions.
    quoted_fun = quoted_values
    |> Enum.uniq_by(fn {_key, quoted_value} -> quoted_value end)
    |> Enum.map(fn {key, quoted_value} ->
      # IO.puts("Generating inverse function '#{fun_name}' for value #{inspect quoted_value} with key '#{key}'")
      quote do
        def unquote(fun_name)(unquote(quoted_value)) do
          unquote(key)
        end
      end
    end)
    quoted_fun_tail = quote do
      def unquote(fun_name)(quoted_value) do
        raise Const.Error, reason: :fetch_value, name: unquote(name), value: quoted_value
      end
    end
    [quoted_fun, quoted_fun_tail]
  end

  defp define_enum_expand_macro(name, fun_name, quoted_values, env) do
    quote do
      defmacro unquote(name)(quoted_key) do
        if is_atom(quoted_key) or Macro.Env.in_match?(__CALLER__) do
          # We must escape the evaluated value as the macro has to return a quoted expression.
          case Keyword.fetch(unquote(quoted_values), quoted_key) do
            {:ok, quoted_value} ->
              # IO.puts("Expanding reference to enum '#{unquote(name)}' for " <>
              #         "#{inspect quoted_key} as literal #{inspect quoted_value}")
              quote do: unquote(Macro.escape(quoted_value))
            :error ->
              raise Const.Error, reason: :fetch, name: unquote(name), key: unescape_var(quoted_key)
          end
        else
          mod = unquote(env.module)
          fun = unquote(fun_name)
          # IO.puts("Expanding reference to enum '#{unquote(name)}' for #{Const.unescape_var(quoted_key)} as " <>
          #         "function call to #{inspect mod}.#{fun}(#{inspect quoted_key})")
          quote do
            apply(unquote(mod), unquote(fun), [unquote(quoted_key)])
          end
        end
      end
    end
  end

  defp eval_quoted_enum(_name, {:__block__, _metadata, quoted_values}, env) do
    # Evaluate the quoted expression corresponding to an enum and return the
    # result as a quoted expression.
    Enum.map(quoted_values, fn {key, _metadata, [quoted_value]} ->
      # IO.puts("Evaluating enum key '#{key}: #{inspect quoted_value}")
      {key, eval_quoted_value(key, quoted_value, env)}
    end)
  end
  defp eval_quoted_enum(name, quoted_values, env) do
    eval_quoted_value(name, quoted_values, env)
  end

  defp eval_quoted_value(name, quoted_value, env) do
    try do
      # First expand the quoted value to resolve module attributes and then
      # evaluate to resolve function calls.
      eval_result = quoted_value
      |> Macro.expand_once(env)
      |> Code.eval_quoted([], env)
      case eval_result do
        {eval_value, []}    ->
          # IO.puts("Expanded key '#{name}' from #{inspect quoted_value} to #{inspect eval_value} (unquoted)")
          Macro.escape(eval_value)
        {_value, vars} ->
          raise Const.Error, reason: :unresolved, name: name, vars: vars
      end
    catch
      _ -> raise Const.Error, reason: :eval, name: name
    end
  end

  @doc """
  Unescape a quoted variable name.
  """
  def unescape_var({key, _metadata, _args}), do: key
  def unescape_var(key) when is_atom(key), do: key
end

defmodule Const.Error do
  defexception reason: nil, name: nil, message: nil

  def exception(opts) do
    reason = opts[:reason]
    name = opts[:name]
    %Const.Error{
      reason: reason,
      name: name,
      message: message(reason, name, opts)
    }
  end

  defp message(reason, name, opts) do
    case reason do
      :eval ->
        "const or enum '#{name}' was assigned a value that could not be evaluated at compile-time"
      :unresolved ->
        "const or enum '#{name}' was assigned a value that depends on the following unresolved variables: #{inspect opts[:vars]}"
      :assign ->
        "enum '#{name}' was not assigned a list of key-value pairs"
      :fetch_key ->
        "key '#{opts[:key]}' is not present in enum '#{name}'"
      :fetch_value ->
        "value #{inspect opts[:value]} is not assigned to any key in enum '#{name}'"
    end
  end
end
