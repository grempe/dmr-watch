defmodule Geocoder do

  @moduledoc """
  A module the provides a simple wrapper around the
  Google Maps Geocoder API and caches its results.

  NOTE : This API has a 2,500 call per day limit.

  e.g.
  {:ok, [%{"formatted_address" => fa}]} = Geocoder.lookup("11746")

  """

  require Logger
  alias Poison, as: JSON

  @user_agent [ {"User-agent", "Elixir DmrWatch"} ]
  # FIXME : Put in config or env var.
  @api_key "AIzaSyA_5BmMgEsx9Mar1jXCj3NEIpsyPPsOoXk"

  def lookup(""), do: { :error, "Empty address string." }
  def lookup(nil), do: { :error, "Nil address string." }

  def lookup(address) do
    address
    |> sanitize_address
    |> get_or_cache_result_for_address
  end

  defp sanitize_address(address) do
    URI.encode(address)
  end

  defp get_or_cache_result_for_address(address) do
    case GeocoderCache.get(address) do
      {:ok, :not_found} ->
        # Rate Limit : 2500 req per 24 hours (86_400_000ms) max
        # FIXME : change to 2500 from 100 when ready
        case ExRated.check_rate("google-geocoder-api", 86_400_000, 500) do
          {:ok, _counter} ->
            Logger.debug "Geocoder.get_or_cache_result_for_address : ext API call required : '#{address}'"
            case http_client_get(address) do
              %{status_code: 200, body: body} ->
                case parse_response_body(body) do
                  {:ok, result} ->
                    :ok = GeocoderCache.put(address, result)
                    {:ok, result}
                  {:error, reason} ->
                    Logger.error "Geocoder.get_or_cache_result_for_address : #{address} : #{reason}"
                    # cache the empty result so we don't query the same thing every second.
                    :ok = GeocoderCache.put(address, [])
                    {:error, reason}
                end
              %{status_code: ___, body: body} ->
                { :error, body }
            end
          {:fail, limit} ->
            Logger.info "Geocoder.lookup : API call : rate limit of #{limit} reached : '#{address}'"
            {:rate_limited, []}
        end
      {:ok, cached_result} ->
        {:ok, cached_result}
    end
  end

  def http_client_get(address) do
    url = "https://maps.googleapis.com/maps/api/geocode/json?address=#{address}&key=#{@api_key}"
    HTTPoison.get(url, @user_agent)
  end

  defp parse_response_body(body) do
    case JSON.decode(body) do
      {:ok, %{"results" => [], "status" => "OVER_QUERY_LIMIT"}} ->
        {:error, :over_query_limit}
      {:ok, %{"results" => [], "status" => "ZERO_RESULTS"}} ->
        {:error, :zero_results}
      {:ok, %{"results" => [], "status" => "REQUEST_DENIED"}} ->
        {:error, :request_denied}
      {:ok, %{"results" => [], "status" => "INVALID_REQUEST"}} ->
        {:error, :invalid_request}
      {:ok, %{"results" => [], "status" => "UNKNOWN_ERROR"}} ->
        {:error, :unknown_error}
      {:ok, %{"results" => results, "status" => "OK"}} ->
        {:ok, Enum.at(results, 0)}
    end
  end

end
