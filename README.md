# Glide

## [![Hex pm](http://img.shields.io/hexpm/v/glide.svg?style=flat)](https://hex.pm/packages/glide) [![Hex Docs](https://img.shields.io/badge/hex-docs-9768d1.svg)](https://hexdocs.pm/glide) [![License](https://img.shields.io/badge/License-MIT-blue.svg)](https://opensource.org/licenses/MIT)![.github/workflows/elixir.yml](https://github.com/maartenvanvliet/glide/workflows/.github/workflows/elixir.yml/badge.svg)
<!-- MDOC !-->

Library to help generating test data using StreamData.

It adds several generators for commonly used values and some convenience wrappers for StreamData, allowing you to generate test data for your tests. The test data is reproducible, i.e. it will use the same seed ExUnit uses, so you'll get the same data if you supply the same seed.

The generators can be used as a stepping stone for property based tests at a later stage.

## Installation

The package can be installed by adding `glide` to your list of dependencies in `mix.exs`:

```elixir
def deps do
  [
    {:glide, "~> 0.9.0"}
  ]
end
```

## Usage

In your tests you can either import or alias Glide depending on your preference

With import syntax it will look like
```elixir
import Glide

gen(:uuid) # creates generator
val(:uuid) # builds val from generator
gen(:uuid) |> val() # builds val from generator
```

If you want to use an alias:
```elixir
alias Glide, as: G

G.gen(:uuid) # creates generator
G.val(:uuid) # builds val from generator
G.gen(:uuid) |> G.val() # builds val from generator
```

Instead of the wrapper functions, you can also use StreamData directly for more control.
```elixir
StreamData.integer() |> G.val
```

### Examples
Create fixed map, with optional subtitle
```elixir
gen(:fixed_map, %{post_id: gen(:uuid), subtitle: optional(gen(:string, [:ascii]))})
```