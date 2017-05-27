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

  enum single_1 do
    first "one"
  end

  enum single_2, do: [first: "one"]

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

  enum atoms, do: [one: :abc, two: :cde, three: :ghi]
  enum strings, do: [one: "abc", two: "def", three: "ghi"]
  enum ints, do: [one: 123, two: 456, three: 789]
  enum floats, do: [one: 123.1, two: 456.2, three: 789.3]
  enum tuples2, do: [one: {"123", 123}, two: {"456", 456}, three: {"789", 789}]
  enum tuples4, do: [one: {"123", 123, :abc, 123.1}, two: {"456", 456, :def, 456.2},
                     three: {"789", 789, :ghi, 789.3}]
  enum lists, do: [one: ["123", "123", "123"], two: ["456", "456", "456"],
                   three: ["789", "789", "789"]]
  enum keywords, do: [one: [abc: "123", def: "456"], two: [ghi: "123", jkl: "456"],
                      three: [mno: "123", pqr: "456"]]
  enum maps, do: [one: %{abc: "123", def: "456"}, two: %{ghi: "123", jkl: "456"},
                  three: %{mno: "123", pqr: "456"}]

  enum duplicates, do: [one: "123", two: "456", three: "456"]
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
    assert :red == Demo.from_color_tuple({255, 0, 0})
  end

  test "enum with literal value as argument (match)" do
    assert Demo.color_tuple(:red) = {255, 0, 0}
    assert :red == Demo.from_color_tuple({255, 0, 0})
  end

  test "enum with variable as argument (comparison)" do
    c = :green
    assert Demo.color(c) == 0xff00
    assert c == Demo.from_color(0xff00)
  end

  test "enum combined with macro resolved at compile-time used in match expression" do
    import Demo
    import Bitwise

    assert color(:red) ||| color(:green) ||| color(:blue) = 0xffffff
  end

  test "enum with single value" do
    assert Demo.single_1(:first) = "one"
    assert Demo.single_2(:first) = "one"
  end

  test "enum inverse with atom values" do
    assert Demo.atoms(:one) = :abc
    assert Demo.from_atoms(:abc) == :one
  end

  test "enum inverse with string values" do
    assert Demo.strings(:two) = "def"
    assert Demo.from_strings("def") == :two
  end

  test "enum inverse with int values" do
    assert Demo.ints(:three) = 789
    assert Demo.from_ints(789) == :three
  end

  test "enum inverse with float values" do
    assert Demo.floats(:one) = 123.1
    assert Demo.from_floats(123.1) == :one
  end

  test "enum inverse with 2-element tuple values" do
    assert Demo.tuples2(:two) = {"456", 456}
    assert Demo.from_tuples2({"456", 456}) == :two
  end

  test "enum inverse with 4-element tuple values" do
    assert Demo.tuples4(:three) = {"789", 789, :ghi, 789.3}
    assert Demo.from_tuples4({"789", 789, :ghi, 789.3}) == :three
  end

  test "enum inverse with list values" do
    assert Demo.lists(:one) = ["123", "123", "123"]
    assert Demo.from_lists(["123", "123", "123"]) == :one
  end

  test "enum inverse with keyword values" do
    assert Demo.keywords(:two) = [ghi: "123", jkl: "456"]
    assert Demo.from_keywords([ghi: "123", jkl: "456"]) == :two
  end

  test "enum inverse with map values" do
    assert Demo.maps(:three) = %{mno: "123", pqr: "456"}
    assert Demo.from_maps(%{mno: "123", pqr: "456"}) == :three
  end

  test "enum inverse with duplicated values" do
    assert Demo.duplicates(:three) = "456"
    assert Demo.from_duplicates("456") == :two
  end
end
