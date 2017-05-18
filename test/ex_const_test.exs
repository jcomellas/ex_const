 # Demo module
defmodule Demo do
  use Const

  require Bitwise

  import Bitwise, only: [bsl: 2]

  const test_atom, do: :abcdef
  const test_string, do: "abcdef"
  const test_int, do: 100
  const test_float, do: 10.0
  const test_tuple2, do: {:abcdef, "abcdef"}
  const test_tuple4, do: {:abcdef, "abcdef", 1234, 1234.0}
  const test_list, do: [:abc, :def, 1234, {123, 456}, 'abcdef']
  const test_keyword, do: [one: 1, two: 2, three: 3]
  const test_map, do: %{"abc" => 123, "def" => 456, "ghi" => 789}

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

  enum color_str, do: [red: "red", green: "green", blue: "blue"]

  @ar "AR"
  @br "BR"
  @it "IT"
  @us "US"

  enum country_code do
    argentina @ar
    brazil    @br
    italy     @it
    usa       @us
  end

  const country_codes, do: [@ar, @br, @it, @us]

  # This function call will be resolved at compile-time.
  const base_path, do: System.cwd()
end

defmodule ConstTest do
  use ExUnit.Case
  doctest Const

  require Demo

  test "const set to atom" do
    assert Demo.test_atom = :abcdef
  end

  test "const set to string" do
    assert Demo.test_string = "abcdef"
  end

  test "const set to integer" do
    assert Demo.test_int = 100
  end

  test "const set to float" do
    assert Demo.test_float = 10.0
  end

  test "const set to tuple (2 elements)" do
    assert Demo.test_tuple2 = {:abcdef, "abcdef"}
  end

  test "const set to tuple (4 elements)" do
    assert Demo.test_tuple4 = {:abcdef, "abcdef", 1234, 1234.0}
  end

  test "const set to list" do
    assert Demo.test_list = [:abc, :def, 1234, {123, 456}, 'abcdef']
  end

  test "const set to keyword" do
    assert Demo.test_keyword = [one: 1, two: 2, three: 3]
  end

  test "const set to map" do
    assert Demo.test_map = %{"abc" => 123, "def" => 456, "ghi" => 789}
  end

  test "const with compile-time expansion assigned to it" do
    assert byte_size(Demo.base_path) > 0
  end

  test "const with module attribute assigned to it" do
    assert Demo.country_codes = ["AR", "BR", "IT", "US"]
  end

  test "enum with literal value as argument (comparison)" do
    assert Demo.color_tuple(:red) == {255, 0, 0}
  end

  test "enum with literal value as argument (match)" do
    assert Demo.color_tuple(:red) = {255, 0, 0}
  end

  test "enum with variable as argument (comparison)" do
    c = :green
    assert Demo.color(c) == 0xff00
  end

  test "enum combined with macro resolved at compile-time used in match expression" do
    import Demo
    import Bitwise

    assert color(:red) ||| color(:green) ||| color(:blue) = 0xffffff
  end
end
