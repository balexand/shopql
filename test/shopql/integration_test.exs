defmodule ShopQL.IntegrationTest do
  use ExUnit.Case, async: true

  @moduletag :integration

  defp opts do
    [
      access_token: System.fetch_env!("SHOPQL_TEST_ACCESS_TOKEN"),
      api_version: "2022-07",
      shop_name: "brian-testing-x"
    ]
  end

  test "request" do
    result =
      ShopQL.request(
        """
        query($gid: ID!) {
          product(id: $gid) {
            variants(first: 5) {
              pageInfo {
                hasNextPage
              },
              edges {
                node {
                  id
                  sellableOnlineQuantity
                }
              }
            }
          }
        }
        """,
        %{gid: "gid://shopify/Product/7595694915746"},
        opts()
      )

    assert {:ok,
            %{
              "product" => %{
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
            },
            %{
              "cost" => %{
                "actualQueryCost" => 6,
                "requestedQueryCost" => 8,
                "throttleStatus" => %{
                  "currentlyAvailable" => _currently_available,
                  "maximumAvailable" => _maximum_available,
                  "restoreRate" => 50.0
                }
              }
            }} = result
  end
end
