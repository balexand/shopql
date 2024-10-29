defmodule MyApp.MoneyV2 do
  use Ecto.Schema

  @primary_key false
  embedded_schema do
    field :amount, :decimal
    field :currency_code, :string
  end
end

defmodule MyApp.AppliedGiftCard do
  use Ecto.Schema

  @primary_key {:id, :string, autogenerate: false}
  embedded_schema do
  end
end

defmodule MyApp.BaseCartLine do
  use Ecto.Schema

  @primary_key {:id, :string, autogenerate: false}
  embedded_schema do
  end
end

defmodule MyApp.CartCost do
  use Ecto.Schema

  @primary_key false
  embedded_schema do
    embeds_one :subtotal_amount, MyApp.MoneyV2
    field :subtotal_amount_estimated, :boolean
  end
end

defmodule MyApp.Cart do
  use Ecto.Schema
  @behaviour ShopQL.GraphQL.Schema

  @primary_key {:id, :string, autogenerate: false}
  embedded_schema do
    embeds_many :applied_gift_cards, MyApp.AppliedGiftCard
    embeds_one :cost, MyApp.CartCost
    embeds_many :lines, MyApp.BaseCartLine
    field :checkout_url, :string
  end

  @impl ShopQL.GraphQL.Schema
  def connection_fields, do: [:lines]
end
