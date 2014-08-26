defmodule DmrMarcRadioImporter do

  @moduledoc """
  A module to download the current DMR-MARC
  database of radio IDs, parse it, and caches
  the results.

  NOTE : This API has no specific API limit,
  but we'll only update hourly to be friendly..

  e.g.
  :ok = DmrMarcRadioImporter.fetch

  """

  require Logger

  @user_agent [ {"User-agent", "Elixir DmrWatch"} ]

  def fetch_every(frequency_in_ms \\ 60_000) when is_integer(frequency_in_ms) do
    fetch
    :timer.sleep(frequency_in_ms)
    fetch_every(frequency_in_ms)
  end

  def fetch do
    case ExRated.check_rate("dmr-marc-radio-importer", 3_600_000, 60) do
      {:ok, _counter} ->
        http_get_html_radio_data_file
      {:fail, limit} ->
        Logger.info "DmrMarcRadioImporter.http_client_get : rate limit of #{limit} reached."
        exit(:normal)
    end
  end

  defp http_get_html_radio_data_file do
    case HTTPoison.get("http://www.n6dva.org/trbo-database/trbo_users_dump.php", @user_agent) do
      %{status_code: 200, body: body} ->
        case parse_html_data(body) do
          {:ok, _result} ->
            :ok
          _ ->
            :error
        end
      %{status_code: ___, body: body} ->
        { :error, body }
    end
  end

  defp parse_html_data(body) do
    result = body
    |> strip_newlines
    |> strip_table_tags
    |> split_into_rows
    |> remove_table_header_row
    |> Enum.map(&split_row_into_columns(&1))
    |> Enum.map(&cache_each_data_row(&1))
    {:ok, result}
  end

  defp strip_newlines(body) do
    body
    |> String.replace("\r", "")
    |> String.replace("\n", "")
    |> String.replace("\t", "")
  end

  defp strip_table_tags(body) do
    body
    |> String.replace("<table border='1'>", "")
    |> String.replace("</table>", "")
  end

  defp split_into_rows(body) do
    body
    |> String.replace("<tr>", "")
    |> String.split("</tr>")
  end

  defp remove_table_header_row(rows) do
    [_h|t] = rows
    t
  end

  defp split_row_into_columns(row) do
    row
    |> String.replace("<td>", "")
    |> String.split("</td>", trim: true)
  end

  defp cache_each_data_row([]) do
    []
  end

  defp cache_each_data_row(row) when is_list(row) do
    [id|data] = row
    id_int = String.to_integer(id)
    :ok = DmrMarcRadioCache.put(id, data)
    row
  end

end
