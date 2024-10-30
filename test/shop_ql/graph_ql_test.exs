defmodule ShopQL.GraphQlTest do
  use ExUnit.Case, async: true

  alias ShopQL.GraphQL

  test "schema_to_fragments/1" do
    expected = """
    fragment MoneyV2Fragment on MoneyV2 {
      amount
      currencyCode
    }

    fragment BaseCartLineFragment on BaseCartLine {
      id
      quantity
    }

    fragment CartCostFragment on CartCost {
      subtotalAmountEstimated
      subtotalAmount { ...MoneyV2Fragment }
    }

    fragment CartFragment on Cart {
      id
      checkoutUrl
      lines(first: 250) { pageInfo { hasNextPage }, nodes { ...BaseCartLineFragment } }
      cost { ...CartCostFragment }
      discountAllocations { ...CartDiscountAllocationFragment }
    }

    fragment CartDiscountAllocationFragment on CartDiscountAllocation {
      targetType
      discountedAmount { ...MoneyV2Fragment }
    }
    """

    assert GraphQL.schema_to_fragments(MyApp.Cart) == expected
  end
end
