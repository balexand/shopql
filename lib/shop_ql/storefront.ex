defmodule ShopQL.Storefront do
  @query_opts_validation [
    storefront_private_token: [
      type: :string,
      required: true,
      doc:
        "Storefront private access token. The [Shopify docs](https://shopify.dev/docs/api/usage/authentication#getting-started-with-private-access) describe several ways to create this token, but the simplest way is using the [Headless](https://apps.shopify.com/headless) app. This is different from the private access token used to access the Admin API as well as the public token used when accessing the Storefront API from the client."
    ],
    api_version: [
      type: :string,
      required: true,
      doc: "Shopify API version, like `2024-10`."
    ],
    req: [
      type: {:struct, Req.Request},
      required: true,
      doc:
        "The `Req.Request` struct. This can be used to configure retries, connection timeouts, etc. The default value is the value returned by `Req.new/0`."
    ],
    shop_name: [
      type: :string,
      required: true,
      doc: "Your Shopify domain is `<shop_name>.myshopify.com`."
    ],
    variables: [
      type: {:map, {:or, [:atom, :string]}, :any},
      default: %{},
      doc: "Map of GraphQL variables."
    ]
  ]

  @doc """

  ## Options

  #{NimbleOptions.docs(@query_opts_validation)}
  """
  def query(query, opts) do
    # FIXME client IP

    opts =
      opts
      |> Keyword.put_new_lazy(:req, fn -> Req.new() end)
      |> NimbleOptions.validate!(@query_opts_validation)

    Req.post!(
      headers: %{"shopify-storefront-private-token" => opts[:storefront_private_token]},
      url: "https://#{opts[:shop_name]}.myshopify.com/api/#{opts[:api_version]}/graphql.json",
      json: %{
        query: query,
        variables: opts[:variables]
      }
    )
    |> case do
      %Req.Response{status: 200, body: %{"data" => data}} -> data
    end

    # FIXME document exceptional error handling
    # FIXME handle non-exceptional errors (https://shopify.dev/docs/api/storefront#status_and_error_codes)
  end
end
