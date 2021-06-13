defmodule Glide do
  @external_resource "README.md"
  @moduledoc @external_resource
             |> File.read!()
             |> String.split("<!-- MDOC !-->")
             |> Enum.fetch!(1)

  @doc """
  Create a value from a generator.

  Mostly wraps StreamData or when the function exists any of the Glide generators

  ```
  Glide.val(:uuid)
  Glide.val(:integer)
  Glide.val(:string, :alphanumeric)
  """
  def val(_data, options \\ [])

  def val(%StreamData{} = data, fun) do
    fun =
      if fun == [] do
        &Function.identity/1
      else
        fun
      end

    pick(data) |> fun.()
  end

  def val(nil, _) do
    val(nil_())
  end

  def val(name, args) when is_atom(name) do
    gen(name, args) |> val
  end

  @doc """
  Create a generator.

  Mostly wraps StreamData or when the function exists any of the Glide generators

  ```
  Glide.gen(:uuid)
  Glide.gen(:integer)
  Glide.gen(:string, :alphanumeric)
  """
  def gen(name, args \\ [])

  def gen(nil, _) do
    nil_()
  end

  def gen(:member_of, args) do
    StreamData.member_of(args)
  end

  def gen(name, args) when is_list(args) do
    if function_exported?(__MODULE__, name, length(args)) do
      apply(__MODULE__, name, args)
    else
      apply(StreamData, name, args)
    end
  end

  def gen(name, arg) do
    gen(name, [arg])
  end

  @doc """
  Creates generator for optional data

  When creating a value from this generator it will either by `nil` or of the type
  passed in as the argument.

    ```
  Glide.optional(Glide.string(:ascii))
  ```
  """
  def optional(data) do
    StreamData.one_of([nil_(), data])
  end

  @doc """
  Create generator for nil constant

  Can also be called with Glide.gen(nil)
  """
  def nil_ do
    StreamData.constant(nil)
  end

  @doc """
  Create generator for a struct

  ```
  struct_of(User, %{
             name: string(:ascii),
             address: optional(string(:ascii))
           })
  ```
  """
  def struct_of(struct, data) do
    StreamData.map(StreamData.fixed_map(data), fn map -> struct!(struct, map) end)
  end

  @doc """
  Merges two StreamData structs, underlying datastructure should
  implement Glide.Merge protocol.

  By default implemented for Map and Keyword lists
  """
  def merge(%StreamData{} = data1, %StreamData{} = data2) do
    StreamData.bind(data1, fn d1 ->
      StreamData.bind(data2, fn d2 ->
        StreamData.constant(Glide.Merge.merge(d1, d2))
      end)
    end)
  end

  def merge(values) when is_list(values) do
    fold_gen(values, &merge(&1, &2))
  end

  @doc """
  Concats two StreamData structs, underlying datastructure should
  implement Glide.Concat protocol.

  Will cast any non StreamData value to a StreamData.constant
  By default implemented for List and String
  """
  def concat(%StreamData{} = data1, %StreamData{} = data2) do
    StreamData.bind(data1, fn d1 ->
      StreamData.bind(data2, fn d2 ->
        StreamData.constant(Glide.Concat.concat(d1, d2))
      end)
    end)
  end

  def concat(%StreamData{} = data, value) when is_binary(value) do
    concat(data, StreamData.constant(value))
  end

  def concat(value, %StreamData{} = data) when is_binary(value) do
    concat(StreamData.constant(value), data)
  end

  def concat(value1, value2) when is_binary(value2) and is_binary(value1) do
    concat(StreamData.constant(value1), StreamData.constant(value2))
  end

  def concat(values) when is_list(values) do
    fold_gen(values, &concat(&1, &2))
  end

  @doc """
      iex> Glide.fold_gen(["1","2","3"], fn doc, acc ->
      ...>   Glide.concat([doc, "!", acc])
      ...> end) |> Glide.val
      "1!2!3"
  """
  def fold_gen(docs, folder_fun)

  def fold_gen([], _folder_fun), do: StreamData.constant([])
  def fold_gen([%StreamData{} = data], _folder_fun), do: data
  def fold_gen([value], _folder_fun), do: StreamData.constant(value)

  def fold_gen([doc | docs], folder_fun) when is_function(folder_fun, 2),
    do: folder_fun.(doc, fold_gen(docs, folder_fun))

  @doc """
  Generates a version 4 (random) UUID generator

      iex> Glide.uuid() |> Glide.val
      "30192e4a-6d03-4f9a-86cb-f301454447c2"
  """
  def uuid() do
    StreamData.map(binuuid(), fn binuuid ->
      {:ok, uuid} = encode(binuuid)
      uuid
    end)
  end

  @doc """
  Generates a version 4 (random) UUID in the binary format generator

      iex> Glide.binuuid() |> Glide.val
      <<130, 204, 75, 232, 2, 161, 72, 182, 138, 181, 5, 244, 199, 120, 124, 155>>
  """
  def binuuid() do
    StreamData.map(StreamData.binary(length: 16), fn <<u0::48, _::4, u1::12, _::2, u2::62>> ->
      <<u0::48, 4::4, u1::12, 2::2, u2::62>>
    end)
  end

  @time_zones ["Etc/UTC"]
  @doc """
  Generates a Date by default somewhere between 1970..2050

      iex> Glide.date(1980..1985) |> Glide.val
      ~D[1984-09-18]
  """
  def date(range \\ 1970..2050) do
    StreamData.tuple(
      {StreamData.integer(range), StreamData.integer(1..12), StreamData.integer(1..31)}
    )
    |> StreamData.bind_filter(fn tuple ->
      case Date.from_erl(tuple) do
        {:ok, date} -> {:cont, StreamData.constant(date)}
        _ -> :skip
      end
    end)
  end

  @doc """
  Generates a Date by default somewhere between 1970..2050

      iex> Glide.time() |> Glide.val
      ~T[14:57:31]
  """
  def time do
    StreamData.tuple(
      {StreamData.integer(0..23), StreamData.integer(0..59), StreamData.integer(0..59)}
    )
    |> StreamData.map(&Time.from_erl!/1)
  end

  @doc """
  Generates a Date by default somewhere between 1970..2050

      iex> Glide.naive_datetime() |> Glide.val
      ~N[2050-01-22 03:54:58]
  """
  def naive_datetime do
    StreamData.tuple({date(), time()})
    |> StreamData.map(fn {date, time} ->
      {:ok, naive_datetime} = NaiveDateTime.new(date, time)
      naive_datetime
    end)
  end

  @doc """
  Generates a Date by default somewhere between 1970..2050

      iex> Glide.datetime() |> Glide.val
      ~U[2050-09-02 22:08:07Z]
  """
  def datetime do
    StreamData.tuple({naive_datetime(), StreamData.member_of(@time_zones)})
    |> StreamData.map(fn {naive_datetime, time_zone} ->
      DateTime.from_naive!(naive_datetime, time_zone)
    end)
  end

  @doc """
  Generates a seed
  """
  def seed(start \\ 0) do
    :rand.seed(:exs1024, start)
  end

  @doc """
  Generate value from StreamData

  Will use a preset seed (e.g. by ExUnit) if available, otherwise will
  create a new seed.

  See https://hexdocs.pm/stream_data/ExUnitProperties.html#pick/1
  """
  def pick(data, start \\ 0) do
    exported_seed =
      case :rand.export_seed() do
        :undefined ->
          # use provided seed if not preseeded (by ExUnit)
          seed(start)

        seed ->
          seed
      end

    seed = :rand.seed_s(exported_seed)

    {size, seed} = :rand.uniform_s(100, seed)
    %StreamData.LazyTree{root: root} = StreamData.__call__(data, seed, size)

    {_, {seed, _}} = seed
    :rand.seed(:exs1024, seed)

    root
  end

  # See https://github.com/elixir-ecto/ecto/blob/v3.6.2/lib/ecto/uuid.ex#L1
  defp encode(
         <<a1::4, a2::4, a3::4, a4::4, a5::4, a6::4, a7::4, a8::4, b1::4, b2::4, b3::4, b4::4,
           c1::4, c2::4, c3::4, c4::4, d1::4, d2::4, d3::4, d4::4, e1::4, e2::4, e3::4, e4::4,
           e5::4, e6::4, e7::4, e8::4, e9::4, e10::4, e11::4, e12::4>>
       ) do
    <<e(a1), e(a2), e(a3), e(a4), e(a5), e(a6), e(a7), e(a8), ?-, e(b1), e(b2), e(b3), e(b4), ?-,
      e(c1), e(c2), e(c3), e(c4), ?-, e(d1), e(d2), e(d3), e(d4), ?-, e(e1), e(e2), e(e3), e(e4),
      e(e5), e(e6), e(e7), e(e8), e(e9), e(e10), e(e11), e(e12)>>
  catch
    :error -> :error
  else
    encoded -> {:ok, encoded}
  end

  @compile {:inline, e: 1}

  defp e(0), do: ?0
  defp e(1), do: ?1
  defp e(2), do: ?2
  defp e(3), do: ?3
  defp e(4), do: ?4
  defp e(5), do: ?5
  defp e(6), do: ?6
  defp e(7), do: ?7
  defp e(8), do: ?8
  defp e(9), do: ?9
  defp e(10), do: ?a
  defp e(11), do: ?b
  defp e(12), do: ?c
  defp e(13), do: ?d
  defp e(14), do: ?e
  defp e(15), do: ?f
end
