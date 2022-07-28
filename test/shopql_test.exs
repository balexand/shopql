defmodule ShopQLTest do
  use ExUnit.Case, async: true
  doctest ShopQL

  import Mox, only: [verify_on_exit!: 1]
  setup :verify_on_exit!

  @errors_result [
    %{
      "extensions" => %{
        "problems" => [
          %{"explanation" => "Expected value to not be null", "path" => []}
        ],
        "value" => nil
      },
      "locations" => [%{"column" => 7, "line" => 1}],
      "message" => "Variable $gid of type ID! was provided invalid value"
    }
  ]

  @extensions_result %{
    "cost" => %{
      "actualQueryCost" => 6,
      "requestedQueryCost" => 8,
      "throttleStatus" => %{
        "currentlyAvailable" => 994,
        "maximumAvailable" => 1.0e3,
        "restoreRate" => 50.0
      }
    }
  }

  @product_result %{
    "variants" => %{
      "edges" => [
        %{
          "node" => %{
            "id" => "gid://shopify/ProductVariant/42424218845346",
            "sellableOnlineQuantity" => 1
          }
        },
        %{
          "node" => %{
            "id" => "gid://shopify/ProductVariant/42424218878114",
            "sellableOnlineQuantity" => 2
          }
        },
        %{
          "node" => %{
            "id" => "gid://shopify/ProductVariant/42424218910882",
            "sellableOnlineQuantity" => 3
          }
        }
      ],
      "pageInfo" => %{"hasNextPage" => false}
    }
  }

  defp opts do
    [
      access_token: "fake_token",
      api_version: "2022-07",
      gql_mod: ShopQL.MockGQL,
      shop_name: "brian-testing-x"
    ]
  end

  test "request" do
    Mox.expect(ShopQL.MockGQL, :query, fn _, _ ->
      {:ok,
       %{
         "data" => %{
           "product" => @product_result
         },
         "extensions" => @extensions_result
       }, []}
    end)

    assert {:ok, %{"product" => @product_result}, @extensions_result} ==
             ShopQL.request(
               "query...",
               %{gid: "gid://shopify/Product/7595694915746"},
               opts()
             )
  end

  test "request with graphql errors" do
    Mox.expect(ShopQL.MockGQL, :query, fn _, _ ->
      {:error, %{"errors" => @errors_result}, []}
    end)

    assert {:error, errors} = ShopQL.request("query...", opts())

    assert errors == [
             %{
               "extensions" => %{
                 "problems" => [%{"explanation" => "Expected value to not be null", "path" => []}],
                 "value" => nil
               },
               "locations" => [%{"column" => 7, "line" => 1}],
               "message" => "Variable $gid of type ID! was provided invalid value"
             }
           ]
  end

  test "request without required options" do
    assert_raise NimbleOptions.ValidationError,
                 "required option :access_token not found, received options: []",
                 fn ->
                   ShopQL.request("", [])
                 end
  end
end
