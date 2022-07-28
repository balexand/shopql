defmodule ShopQLTest do
  use ExUnit.Case, async: true
  doctest ShopQL

  import ExUnit.CaptureLog

  import Mox, only: [verify_on_exit!: 1]
  setup :verify_on_exit!

  @gid "gid://shopify/Product/7595694915746"

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

  @rate_limit_errors_result [
    %{
      "extensions" => %{
        "code" => "THROTTLED",
        "documentation" => "https://shopify.dev/api/usage/rate-limits"
      },
      "message" => "Throttled"
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

  test "query" do
    Mox.expect(ShopQL.MockGQL, :query, fn "query...", opts ->
      assert opts == [
               headers: [{"X-Shopify-Access-Token", "fake_token"}],
               url: "https://brian-testing-x.myshopify.com/admin/api/2022-07/graphql.json",
               variables: %{gid: "gid://shopify/Product/7595694915746"}
             ]

      {:ok,
       %{
         "data" => %{"product" => @product_result},
         "extensions" => @extensions_result
       }, []}
    end)

    assert {:ok, %{"product" => @product_result}, @extensions_result} ==
             ShopQL.query(
               "query...",
               %{gid: @gid},
               opts()
             )
  end

  test "query with graphql errors" do
    Mox.expect(ShopQL.MockGQL, :query, fn _, _ ->
      {:error, %{"errors" => @errors_result}, []}
    end)

    assert {:error, errors} = ShopQL.query("query...", opts())

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

  test "query without required options" do
    assert_raise NimbleOptions.ValidationError,
                 "required option :access_token not found, received options: []",
                 fn ->
                   ShopQL.query("", [])
                 end
  end

  describe "rate limit exceeded error" do
    test "retries twice then succeeds on third try" do
      Mox.expect(ShopQL.MockGQL, :query, 2, fn _, _ ->
        {:error, %{"errors" => @rate_limit_errors_result, "extensions" => @extensions_result}, []}
      end)

      Mox.expect(ShopQL.MockGQL, :query, fn _, _ ->
        {:ok,
         %{
           "data" => %{"product" => @product_result},
           "extensions" => @extensions_result
         }, []}
      end)

      log =
        capture_log([level: :warn], fn ->
          assert {:ok, %{"product" => @product_result}, @extensions_result} ==
                   ShopQL.query("query...", %{gid: @gid}, opts())
        end)

      assert log =~ ~R{delaying 120ms before retry.+delaying 120ms before retry}s
    end

    test "retries 3 times then fails" do
      Mox.expect(ShopQL.MockGQL, :query, 3, fn _, _ ->
        {:error, %{"errors" => @rate_limit_errors_result, "extensions" => @extensions_result}, []}
      end)

      capture_log([level: :warn], fn ->
        assert {:error, @rate_limit_errors_result} ==
                 ShopQL.query("query...", %{gid: @gid}, opts())
      end)
    end
  end
end
