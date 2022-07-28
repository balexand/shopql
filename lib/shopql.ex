defmodule ShopQL do
  @moduledoc """
  TODO
  """

  require Logger

  @query_opts_validation [
    access_token: [
      type: :string,
      required: true,
      doc: "Shopify access token."
    ],
    api_version: [
      type: :string,
      required: true,
      doc: "Shopify API version, like `2022-07`."
    ],
    gql_mod: [
      type: :atom,
      default: GQL,
      doc: false
    ],
    max_attempts: [
      type: :pos_integer,
      default: 1,
      doc:
        "Maximum number of attempts to make. It is only safe to set this to a value > 1 if your query is idempotent."
    ],
    max_attempts_throttled: [
      type: :pos_integer,
      default: 3,
      doc:
        "Maximum number of attempts to make. This only applies when Shopify returns an error indicating that the rate limit has been exceeded."
    ],
    min_retry_delay: [
      type: :pos_integer,
      default: 250,
      doc:
        "Delay in ms between failed attempts. The delay will be doubled after each subsequent retry. For example, with the default value the first delay will be 250ms, the second 500ms, and the third 750ms. This doesn't apply when a rate limit error occurs."
    ],
    shop_name: [
      type: :string,
      required: true,
      doc: "Your Shopify domain is `<shop_name>.myshopify.com`."
    ]
  ]

  @doc """
  Submits a query to the [Shopify Admin GraphQL API](https://shopify.dev/api/admin-graphql).

  ## Options

  #{NimbleOptions.docs(@query_opts_validation)}

  ## Retries after error

  The retry logic depends upon the type of error:

  * Connection errors like a 5xx HTTP response or timeout - Request will be retried up to
    `:max_attempts` times. For this type of error we don't know whether or not Shopify ran the
    query. Therefore, only increase `:max_attempts` if you are running an idempotent query. The
    `:min_retry_delay` setting applies in this case.
  * Rate limit exceeded error - Failed request will be retried up to `:max_attempts_throttled`
    times. For this type of error we know that Shopify didn't run the query so it is safe to retry
    even if your query is not idempotent. Will delay between requests for enough time for
    [Shopify's cost points](https://shopify.dev/api/admin-graphql#rate_limits) to be fully
    replenished.
  * GraphQL error ("errors" key in response) - Request will never be retried because this type of
    error generally means that your request is invalid and if we retry we'll just get the same
    error again.
  """
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
