defmodule ShopQL do
  @moduledoc """
  TODO
  """

  @request_opts_validation [
    access_token: [
      type: :string,
      required: true
    ],
    api_version: [
      type: :string,
      required: true
    ],
    gql_mod: [
      type: :atom,
      default: GQL,
      doc: false
    ],
    shop_name: [
      type: :string,
      required: true
    ]
  ]

  def request(query, variables \\ %{}, opts) do
    opts = NimbleOptions.validate!(opts, @request_opts_validation)

    case opts[:gql_mod].query(query, Keyword.merge(gql_opts(opts), variables: variables)) do
      {:ok, %{"data" => _data, "extensions" => _extensions}, _headers} = resp -> resp
    end
  end

  defp gql_opts(opts) do
    [
      headers: [{"X-Shopify-Access-Token", opts[:access_token]}],
      url:
        "https://#{opts[:shop_name]}.myshopify.com/admin/api/#{opts[:api_version]}/graphql.json"
    ]
  end
end
