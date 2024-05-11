defmodule ShopQL.IntegrationTest do
  use ExUnit.Case, async: true

  @moduletag :integration

  @product_availability_query """
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
  """

  @gid "gid://shopify/Product/7595694915746"

  defp opts do
    [
      access_token: System.fetch_env!("SHOPQL_TEST_ACCESS_TOKEN"),
      api_version: "2022-07",
      shop_name: "brian-testing-x"
    ]
  end

  test "query" do
    assert {:ok, %{"data" => data, "extensions" => extensions}} =
             ShopQL.query(@product_availability_query, %{gid: @gid}, opts())

    assert data == %{
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
           }

    assert %{
             "cost" => %{
               "actualQueryCost" => _,
               "requestedQueryCost" => _,
               "throttleStatus" => %{
                 "currentlyAvailable" => _,
                 "maximumAvailable" => _,
                 "restoreRate" => _
               }
             }
           } = extensions
  end

  test "query with missing variable" do
    assert {:error, %{"errors" => errors}} = ShopQL.query(@product_availability_query, opts())

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
end
