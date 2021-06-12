defmodule GlideTest do
  use ExUnit.Case, async: true

  import Glide

  defmodule User do
    defstruct [:name, :address]
  end

  test "StreamData generators" do
    assert gen(:string, :alphanumeric) |> val == "BslPwbWl0vN0txSPZxuOy0b2nbR9gEaOfAJCbj"
  end

  test "nil" do
    assert val(nil) == nil
    assert gen(nil) |> val == nil
    assert nil_() |> val == nil
  end

  test "date" do
    assert val(:date) == ~D[1989-09-01]
    assert gen(:date) |> val() == ~D[1980-01-22]
  end

  test "time" do
    assert val(:time) == ~T[11:36:51]
    assert gen(:time) |> val() == ~T[00:51:41]
  end

  test "datetime" do
    assert val(:datetime) == ~U[2028-06-15 13:02:12Z]
    assert gen(:datetime) |> val() == ~U[1970-02-24 03:07:50Z]
  end

  test "naive datetime" do
    assert val(:naive_datetime) == ~N[2010-01-17 04:28:13]
    assert gen(:naive_datetime) |> val() == ~N[2038-03-31 08:30:54]
  end

  test "uuid" do
    assert val(:uuid) == "df1e2852-17a9-40b3-9432-72426f4257d0"
    assert gen(:uuid) |> val() == "a842e0ac-5217-4920-b3d4-3272426f4257"
    assert uuid() |> val() == "688e5c39-ac52-47a9-a0b3-d43272426f42"
  end

  describe "concat" do
    test "strings" do
      assert concat(gen(:string, :ascii), gen(:string, :ascii)) |> val ==
               "x3=ZrN`b$E1M~~SZRN)Enzh0)9guLnaNiQ"

      assert concat([gen(:string, :ascii), "@", gen(:string, :printable)]) |> val == "uLnaNiQ@򽱤򧱌򄥒"
    end

    test "lists" do
      assert [_ | _] = concat(gen(:list_of, gen(:integer)), gen(:list_of, gen(:binary))) |> val
      assert [_ | _] = concat([gen(:list_of, gen(:integer)), gen(:list_of, gen(:integer))]) |> val
    end
  end

  describe "merge" do
    test "maps" do
      Glide.seed(100)

      assert merge(
               gen(:fixed_map, %{a: gen(:constant, 1)}),
               gen(:optional_map, %{
                 c: gen(:integer),
                 d: gen(:integer)
               })
             )
             |> val == %{a: 1, c: 2}
    end

    test "keyword lists" do
      Glide.seed(1)

      assert merge([
               gen(:fixed_map, %{a: gen(:constant, 1)}),
               gen(:keyword_of, gen(:integer))
             ])
             |> val == %{a: 1, eSvXK0OtAALfqrc: -15, zGcjj3k6FO: -11}
    end
  end

  test "structs" do
    assert struct_of(User, %{
             name: gen(:string, :ascii),
             address: optional(gen(:string, :ascii))
           })
           |> val == %GlideTest.User{address: "pEjL+", name: "LLoR;l@cY%"}
  end
end
