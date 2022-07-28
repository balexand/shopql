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
    ShopQL.request(
      """
      query($gid: ID!) {
        product(id: $gid) {
          variants(first: 25) {
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
    |> IO.inspect()
  end
end
