defmodule Geocoder do

  @moduledoc """
  A module the provides a simple wrapper around the
  Google Maps Geocoder API and caches its results.

  NOTE : This API has a 2,500 call per day limit.

  e.g.
  {:ok, [%{"formatted_address" => fa}]} = Geocoder.lookup("11746")

  """

  @user_agent [ {"User-agent", "Elixir DmrWatch"} ]
  # FIXME : Put in config or env var.
  @api_key "AIzaSyA_5BmMgEsx9Mar1jXCj3NEIpsyPPsOoXk"

  def lookup(""), do: { :error, "Empty address string." }
  def lookup(nil), do: { :error, "Nil address string." }

  def lookup(address) do
    address
    |> sanitize_address
    |> get_cached_result_for_address
  end

  defp sanitize_address(address) do
    URI.encode(address)
  end

  defp get_cached_result_for_address(address) do
    case GeocoderCache.get(address) do
      {:ok, cached_results} ->
        cached_results
      {:error, nil} ->
        case http_client_get(address) do
          %{status_code: 200, body: body} ->
            case parse_response_body(body) do
              {:ok, results} ->
                :ok = GeocoderCache.put(address, {:ok, results})
                {:ok, results}
              {:error, body} ->
                {:error, body}
            end
          %{status_code: ___, body: body} ->
            { :error, body }
        end
    end
  end

  defp http_client_get(address) do
    url = "https://maps.googleapis.com/maps/api/geocode/json?address=#{address}&key=#{@api_key}"
    HTTPoison.get(url, @user_agent)
  end

  defp parse_response_body(body) do
    use Jazz

    case JSON.decode!(body) do
      %{"results" => results} ->
        {:ok, results}
      _ ->
        {:error, body}
    end
  end

end
