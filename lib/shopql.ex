defmodule ShopQL do
  @moduledoc """
  TODO
  """

  require Logger

  @query_opts_validation [
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
    max_attempts_throttled: [
      type: :pos_integer,
      default: 3,
      doc: "Maximum number of attempts to make after receiving rate limit throttled error."
    ],
    shop_name: [
      type: :string,
      required: true
    ]
  ]

  def query(query, variables \\ %{}, opts) do
    opts = NimbleOptions.validate!(opts, @query_opts_validation)

    case opts[:gql_mod].query(query, Keyword.merge(gql_opts(opts), variables: variables)) do
      {:ok, %{"data" => data, "extensions" => extensions}, _headers} ->
        {:ok, data, extensions}

      {:error,
       %{
         "errors" => [%{"extensions" => %{"code" => "THROTTLED"}}] = errors,
         "extensions" => extensions
       }, _headers} ->
        if opts[:max_attempts_throttled] > 1 do
          delay_until_quota_fully_replenished(extensions)
          query(query, variables, Keyword.update!(opts, :max_attempts_throttled, &(&1 - 1)))
        else
          {:error, errors}
        end

      {:error, %{"errors" => errors}, _headers} ->
        {:error, errors}
    end
  end

  defp delay_until_quota_fully_replenished(%{
         "cost" => %{
           "throttleStatus" => %{
             "currentlyAvailable" => currently_available,
             "maximumAvailable" => max_available,
             "restoreRate" => restore_rate
           }
         }
       }) do
    delay = round((max_available - currently_available) * 1000 / restore_rate) |> max(0)

    Logger.warn("Shopify rate limit exceeded; delaying #{delay}ms before retry")
    :timer.sleep(delay)
  end

  defp gql_opts(opts) do
    [
      headers: [{"X-Shopify-Access-Token", opts[:access_token]}],
      url:
        "https://#{opts[:shop_name]}.myshopify.com/admin/api/#{opts[:api_version]}/graphql.json"
    ]
  end
end
