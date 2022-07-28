defmodule ShopQLTest do
  use ExUnit.Case, async: true
  doctest ShopQL

  test "request without required options" do
    assert_raise NimbleOptions.ValidationError,
                 "required option :access_token not found, received options: []",
                 fn ->
                   ShopQL.request("", [])
                 end
  end
end
