defmodule Netwatch do

  @moduledoc """
  A module to call the NetWatch API URL, and parse its contents
  into a %Netwatch{} Struct.

  Netwatch API Response Body Structure:

    - There are two sections, separated by the Backspace Char (\\b).
      The first section contains records for who is talking live now.
      The second section contains records for previous transmissions.
      If there is no-one talking live now the first section will be
      a list of eight empty strings. ["", "", "", "", "", "", "", ""]

    - Records within each section are separated by a TAB (\\t).

    - Within each record, eight attribute columns are separated by the
      Vertical Tab char (\\v). The Vertical Tab (aka VT, \\v, 0x0b) is
      explained here:

        http://stackoverflow.com/questions/3380538/what-is-a-vertical-tab

    - Attributes of each record (in order) are:
      start_time
      duration_in_seconds
      peer_alias
        peer_callsign (derived from peer_alias)
        peer_location (derived from peer_alias)
        peer_id (derived from peer_alias, sometimes this is the only part avail)
      radio_alias
        radio_callsign (derived from radio_alias)
        radio_name (derived from radio_alias)
        radio_location (derived from radio_alias)
        radio_id (derived from radio_alias, sometimes this is the only part avail)
      bridge_group_name
      rssi_in_dbm
      site_name
      loss_percentage
  """

  defstruct start_time: "",
            duration_in_seconds: 0,
            peer_alias: nil,
            peer_callsign: nil,
            peer_location: nil,
            peer_id: 0,
            radio_alias: nil,
            radio_callsign: nil,
            radio_name: nil,
            radio_location: nil,
            radio_id: 0,
            bridge_group_name: "",
            rssi_in_dbm: 0.0,
            site_name: "",
            loss_percentage: 0.0

  @user_agent [ {"User-agent", "Elixir DmrWatch"} ]

  def fetch do
    netwatch_url
    |> HTTPoison.get(@user_agent)
    |> handle_response
  end

  def fetch_every(frequency_in_ms \\ 1000) do
    import :timer, only: [ sleep: 1 ]
    IO.puts "Fetching every #{frequency_in_ms}ms..."
    fetch
    sleep frequency_in_ms
    fetch_every(frequency_in_ms)
  end

  defp netwatch_url do
    "http://107.170.211.99:42420/data.txt?param=ajaxminimalnetwatch"
  end

  defp handle_response(%{status_code: 200, body: body}), do: { :ok, extract_sections(body) }
  defp handle_response(%{status_code: ___, body: body}), do: { :error, body }

  defp extract_sections(body) do
    String.split(body, "\b")
    |> Enum.map(&extract_records(&1))
  end

  defp extract_records(section) do
    String.split(section, "\t")
    |> Enum.map(&extract_columns(&1))
    |> Enum.map(&convert_to_struct(&1))
    |> Enum.map(&split_peer_alias(&1))
    |> Enum.map(&split_radio_alias(&1))
  end

  defp extract_columns(record) do
    String.split(record, "\v")
    |> Enum.map(&remove_nbsp(&1))
    |> Enum.map(&remove_whitespace(&1))
  end

  defp convert_to_struct(record) do
    case record do
      [start_time,
       duration_in_seconds,
       peer_alias,
       radio_alias,
       bridge_group_name,
       rssi_in_dbm,
       site_name,
       loss_percentage] ->
         %Netwatch{start_time: parse_timestamp(start_time),
                   duration_in_seconds: convert_to_float(duration_in_seconds),
                   peer_alias: peer_alias,
                   radio_alias: radio_alias,
                   bridge_group_name: bridge_group_name,
                   rssi_in_dbm: convert_to_float(rssi_in_dbm),
                   site_name: site_name,
                   loss_percentage: String.replace(loss_percentage, "%", "") |> convert_to_float
                  }
      _ ->
        nil
    end
  end

  defp split_peer_alias(nw_struct) do
    case nw_struct do
      %Netwatch{peer_alias: peer_alias} = nw_struct ->
        if peer_alias != "" do
          split_peer_alias(nw_struct, String.split(peer_alias, " - "))
        end
      _ ->
        # nothing
    end
  end

  defp split_peer_alias(nw_struct, [peer_id]) do
    %Netwatch{ nw_struct | radio_id: convert_to_integer(peer_id)}
  end

  defp split_peer_alias(nw_struct, [peer_callsign, location_and_id]) do
    [peer_location, peer_id] = String.split(location_and_id, " -- ")
    %Netwatch{ nw_struct | peer_callsign: peer_callsign,
                           peer_location: peer_location,
                           peer_id: convert_to_integer(peer_id)}
  end

  defp split_radio_alias(nw_struct) do
    case nw_struct do
      %Netwatch{radio_alias: radio_alias} = nw_struct ->
        if radio_alias != "" do
          split_radio_alias(nw_struct, String.split(radio_alias, " - "))
        end
      _ ->
        # nothing
    end
  end

  defp split_radio_alias(nw_struct, [radio_id]) do
    %Netwatch{ nw_struct | radio_id: convert_to_integer(radio_id)}
  end

  defp split_radio_alias(nw_struct, [radio_callsign, radio_name, location_and_radio_id]) do
    [radio_location, radio_id] = String.split(location_and_radio_id, " -- ")
    %Netwatch{ nw_struct | radio_callsign: radio_callsign,
                           radio_name: radio_name,
                           radio_location: radio_location,
                           radio_id: convert_to_integer(radio_id)}
  end

  defp remove_nbsp(column) do
    String.replace(column, "&nbsp;", " ")
  end

  defp remove_whitespace(column) do
    String.strip(column)
  end

  defp convert_to_float(string_num) do
    case string_num do
      "" ->
        0.0
      "Not avail." ->
        0.0
      _ ->
        String.to_float(string_num)
    end
  end

  defp convert_to_integer(string_num) do
    case string_num do
      "" ->
        0
      "Not avail." ->
        0
      _ ->
        String.to_integer(string_num)
    end
  end

  def parse_timestamp(ts) do
    # Sample : "03:48:38.471 Aug 5" to "2014-08-05T03:48:38+0000"

    if String.valid?(ts) do
      time = Regex.run(~r/^\d\d:\d\d:\d\d/, ts)
             |> parse_time
      year = Timex.Date.now.year
      month = Timex.Date.now.month
      day = Regex.run(~r/\d*\d$/, ts)
            |> parse_day
    end

    Timex.Date.from({{year,month,day},time})
    |> Timex.DateFormat.format!("{ISO}")
  end

  defp parse_time(t) when is_list(t) do
     List.first(t)
     |> parse_time
  end
  defp parse_time(t) when is_binary(t) do
    String.split(t, ":")
    |> Enum.map(&String.to_integer(&1))
    |> List.to_tuple
  end
  defp parse_time(t) when t == nil do
    # Something is wrong with input timestamp. Replace with current time.
    {Timex.Date.now.hour, Timex.Date.now.minute, Timex.Date.now.second}
  end

  defp parse_day(d) when is_list(d) do
     List.first(d)
     |> parse_day
  end
  defp parse_day(d) when is_binary(d) do
    String.to_integer(d)
  end
  defp parse_day(d) when d == nil do
    # Something is wrong with input timestamp. Replace with today's day Integer.
    Timex.Date.now.day
  end

end
