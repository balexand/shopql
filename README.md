# ShopQL

[![Package](https://img.shields.io/badge/-Package-important)](https://hex.pm/packages/shopql) [![Documentation](https://img.shields.io/badge/-Documentation-blueviolet)](https://hexdocs.pm/shopql)

Simple Shopify GraphQL client for Elixir.

## Installation

The package can be installed by adding `shopql` to your list of dependencies in `mix.exs`:

```elixir
def deps do
  [
    {:shopql, "~> 0.1.0"}
  ]
end
```

## Usage

[See the docs](https://hexdocs.pm/shopql/ShopQL.html).

## Retrying failed requests

This library supports retrying failed requests. The default settings are safe regardless of whether or not your request is idempotent. See [`ShopQL.query/3`](https://hexdocs.pm/shopql/ShopQL.html#query/3) for details.

## Request throttling

This library does not attemp to preventatively throttle requests to avoid Shopify's rate limit. You're application is responsible for this.
