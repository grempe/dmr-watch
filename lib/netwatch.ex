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

      time_peer_radio_hash_id : A hash Integer calculated from String concatenation of the
                                start_time, peer_id, and radio_id fields.  This hash is
                                used to detect duplicates (there are many on each API response).
                                A certain radio, transmitting through a certain peer at a certain
                                time should be enough to detect any duplicate.
  """

  require Logger

  defstruct start_time: "",
            duration_in_seconds: 0,
            peer_alias: nil,
            peer_callsign: nil,
            peer_location: nil,
            peer_id: 0,
            peer_latitude: nil,
            peer_longitude: nil,
            peer_formatted_address: nil,
            radio_alias: nil,
            radio_callsign: nil,
            radio_name: nil,
            radio_location: nil,
            radio_id: 0,
            radio_latitude: nil,
            radio_longitude: nil,
            radio_formatted_address: nil,
            dmr_marc_radio_callsign: nil,
            dmr_marc_radio_name: nil,
            dmr_marc_radio_city: nil,
            dmr_marc_radio_state: nil,
            dmr_marc_radio_country: nil,
            dmr_marc_radio_home_repeater: nil,
            dmr_marc_radio_remarks: nil,
            bridge_group_name: "",
            rssi_in_dbm: 0.0,
            site_name: "",
            loss_percentage: 0.0,
            time_peer_radio_hash_id: nil

  @user_agent [ {"User-agent", "Elixir DmrWatch"} ]

  def fetch do
    try do
      case HTTPoison.get(netwatch_url, @user_agent) do
        %HTTPoison.Response{status_code: 200, body: body} ->
          :ok = GenEvent.sync_notify(:dmrwatch_event_manager, {:server, :status, nil})
          {:ok, extract_sections(body)}
        %HTTPoison.Response{status_code: ___, body: body} ->
          {:error, body}
      end
    rescue
      error in [HTTPoison.HTTPError, HTTPoison.Error] ->
        # Exit cleanly so we don't kill the Phoenix supervisor.
        # Periodic errors retrieving data from external CBridge are to be expected.
        Logger.error "Netwatch.fetch : Error retrieving data from c-Bridge. Try again next time. : #{error.message}"
        :ok = GenEvent.sync_notify(:dmrwatch_event_manager, {:server, :status, "Server Error : The c-Bridge server is unavailable. Realtime data is paused."})
        exit(:normal)
    end
  end

  defp netwatch_url do
    "http://107.170.211.99:42420/data.txt?param=ajaxminimalnetwatch"
  end

  defp extract_sections(body) do
    String.split(body, "\b")
    |> Enum.map(&extract_records(&1))
    |> List.flatten
    |> Enum.filter(fn(nw_struct) -> struct_is_valid?(nw_struct) end )
    |> Enum.map(&notify_dmrwatch_event_manager(&1))
  end

  defp extract_records(section) do
    String.split(section, "\t")
    |> Enum.map(&extract_columns(&1))
    |> Enum.map(&convert_to_struct(&1))
    |> Enum.filter(fn(nw_struct) -> if nw_struct, do: true, else: false end )  # filter nil nw_struct
    |> Enum.map(&split_peer_alias(&1))
    |> Enum.map(&split_radio_alias(&1))
    |> Enum.map(&lookup_dmr_marc_radio_data(&1))
    |> Enum.map(&geocode_location(:radio, &1))
    |> Enum.map(&geocode_location(:peer, &1))
    |> Enum.map(&generate_struct_hash_id(&1))
    |> Enum.filter(fn(nw_struct) ->
                     case nw_struct do
                       %Netwatch{time_peer_radio_hash_id: time_peer_radio_hash_id} ->
                         Cache.new?({:netwatch, time_peer_radio_hash_id})
                       _ ->
                         false
                     end
                   end)
    |> Enum.map(&register_time_peer_radio_hash_id(&1))
  end

  defp struct_is_valid?(%Netwatch{radio_id: radio_id, peer_id: peer_id}) when radio_id > 0 and peer_id > 0 do
    true
  end

  defp struct_is_valid?(%Netwatch{radio_id: radio_id, peer_id: peer_id}) when radio_id == 0 or peer_id == 0 do
    false
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
         %Netwatch{time_peer_radio_hash_id: "",
                   start_time: parse_timestamp(start_time),
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

  defp split_peer_alias(%Netwatch{peer_alias: ""} = nw_struct) do
    nw_struct
  end

  defp split_peer_alias(%Netwatch{peer_alias: nil} = nw_struct) do
    nw_struct
  end

  defp split_peer_alias(%Netwatch{peer_alias: peer_alias} = nw_struct) do
    split_peer_alias(nw_struct, String.split(peer_alias, " - "))
  end

  defp split_peer_alias(%Netwatch{} = nw_struct, [peer_id]) do
    %Netwatch{ nw_struct | peer_id: convert_to_integer(peer_id)}
  end

  defp split_peer_alias(%Netwatch{} = nw_struct, [peer_callsign, location_and_id]) do
    [peer_location, peer_id] = String.split(location_and_id, " -- ")
    %Netwatch{ nw_struct | peer_callsign: peer_callsign,
                           peer_location: peer_location,
                           peer_id: convert_to_integer(peer_id)}
  end

  defp split_radio_alias(%Netwatch{radio_alias: ""} = nw_struct) do
    nw_struct
  end

  defp split_radio_alias(%Netwatch{radio_alias: nil} = nw_struct) do
    nw_struct
  end

  defp split_radio_alias(%Netwatch{radio_alias: radio_alias} = nw_struct) do
    cond do
      Regex.match?(~r/^(\w+)\s*-\s*(\w+)\s*-\s*([\w+.{0,1},{0,1}\-{0,1}\s]+)--\s*(\d+)$/, radio_alias) ->
        # "N6BMW - Dan - Ojai California USA -- 3106370"
        # "WB8SFY - Mark - Commerce Twp. Michigan USA -- 3126248"
        # "WF6R - Stephan -Palo Alto California USA -- 3106448"
        # "IK4UPB - Gabriele - Castelfranco Emilia Emilia-Romagna ITA -- 2224004"
        [_h | [radio_callsign, radio_name, radio_location, radio_id]] = Regex.run(~r/^(\w+)\s*-\s*(\w+)\s*-\s*([\w+.{0,1},{0,1}\-{0,1}\s]+)--\s*(\d+)$/, radio_alias)
        split_radio_alias(nw_struct, [radio_callsign, radio_name, radio_location, radio_id])
      Regex.match?(~r/^\d+$/, radio_alias) ->
        # "3106370"
        split_radio_alias(nw_struct, [radio_alias])
      Regex.match?(~r/^(\w+)\s(\w+)\s+([\w+,{0,1}\s]+)-\s+(\d+)$/, radio_alias) ->
        # "K6ACR Sam Turlock California United States - 31070"
        [_h | [radio_callsign, radio_name, radio_location, radio_id]] = Regex.run(~r/^(\w+)\s(\w+)\s+([\w+,{0,1}\s]+)-\s+(\d+)$/, radio_alias)
        split_radio_alias(nw_struct, [radio_callsign, radio_name, radio_location, radio_id])
      true ->
        Logger.debug "ERROR : Unknown radio_alias format : '#{radio_alias}'"
        nw_struct
    end
  end

  defp split_radio_alias(%Netwatch{} = nw_struct, [radio_id]) do
    %Netwatch{ nw_struct | radio_id: convert_to_integer(radio_id)}
  end

  defp split_radio_alias(%Netwatch{} = nw_struct, [radio_callsign, radio_name, radio_location, radio_id]) do
    %Netwatch{ nw_struct | radio_callsign: radio_callsign,
                           radio_name: radio_name,
                           radio_location: radio_location,
                           radio_id: convert_to_integer(radio_id)}
  end

  defp lookup_dmr_marc_radio_data(%Netwatch{radio_id: radio_id} = nw_struct) when radio_id > 0 do
    case Cache.get({:dmr_marc_radio, radio_id}) do
      {:ok, :not_found} ->
        #Logger.warn "lookup_dmr_marc_radio_id : NOT FOUND : #{radio_id}"
        nw_struct
      {:ok, data} ->
        new_nw_struct = %Netwatch{ nw_struct | dmr_marc_radio_callsign:      data.callsign,
                                               dmr_marc_radio_name:          data.name,
                                               dmr_marc_radio_city:          data.city,
                                               dmr_marc_radio_state:         data.state,
                                               dmr_marc_radio_country:       data.country,
                                               dmr_marc_radio_home_repeater: data.home_repeater,
                                               dmr_marc_radio_remarks:       data.remarks }
        new_nw_struct
    end
  end

  defp lookup_dmr_marc_radio_data(%Netwatch{radio_id: radio_id} = nw_struct) when radio_id == 0 do
    # This is a default struct.  Just return it.
    nw_struct
  end

  defp geocode_location(:radio, %Netwatch{radio_location: ""} = nw_struct) do
    nw_struct
  end

  defp geocode_location(:radio, %Netwatch{radio_location: nil} = nw_struct) do
    nw_struct
  end

  defp geocode_location(:radio, %Netwatch{} = nw_struct) do
    location = choose_dmr_marc_or_extracted_location(nw_struct)

    case geocode_location_extract(location) do
      {:ok, [fa, lat, lng]} ->
        %Netwatch{ nw_struct | radio_formatted_address: fa,
                               radio_latitude: lat,
                               radio_longitude: lng}
      {:error, []} ->
        nw_struct
    end
  end

  defp geocode_location(:peer, %Netwatch{peer_location: ""} = nw_struct) do
    nw_struct
  end

  defp geocode_location(:peer, %Netwatch{peer_location: nil} = nw_struct) do
    nw_struct
  end

  defp geocode_location(:peer, %Netwatch{peer_location: location} = nw_struct) do
    case geocode_location_extract(location) do
      {:ok, [fa, lat, lng]} ->
        %Netwatch{ nw_struct | peer_formatted_address: fa,
                               peer_latitude: lat,
                               peer_longitude: lng}
      {:error, []} ->
        nw_struct
    end
  end

  defp geocode_location_extract(location) do
    case Geocoder.lookup(location) do
      {:ok, %{"formatted_address" => fa, "geometry" => %{"location" => %{"lat" => lat, "lng" => lng} } } } ->
        {:ok, [fa, lat, lng]}
      _ ->
        {:error, []}
    end
  end

  defp choose_dmr_marc_or_extracted_location(%Netwatch{} = nw_struct) do
    case nw_struct do
      %Netwatch{dmr_marc_radio_city: nil, dmr_marc_radio_state: nil, dmr_marc_radio_country: nil, radio_location: radio_location} ->
        #Logger.debug "choose_dmr_marc_or_extracted_location : radio_location : #{radio_location}"
        radio_location
      %Netwatch{dmr_marc_radio_city: dmr_marc_radio_city, dmr_marc_radio_state: dmr_marc_radio_state, dmr_marc_radio_country: dmr_marc_radio_country} ->
        #Logger.debug "choose_dmr_marc_or_extracted_location : DMR-MARC location : #{dmr_marc_radio_city}, #{dmr_marc_radio_state}, #{dmr_marc_radio_country}"
        "#{dmr_marc_radio_city}, #{dmr_marc_radio_state}, #{dmr_marc_radio_country}"
    end
  end

  defp generate_struct_hash_id(%Netwatch{start_time: start_time, peer_id: peer_id, radio_id: radio_id} = nw_struct) do
    generate_struct_hash_id(nw_struct, [start_time, peer_id, radio_id])
  end

  defp generate_struct_hash_id(%Netwatch{} = nw_struct, [start_time, peer_id, radio_id]) do
    hash = Enum.map([start_time, peer_id, radio_id], &to_string(&1))
    |> List.to_string
    |>:erlang.phash2

    %Netwatch{ nw_struct | time_peer_radio_hash_id: hash}
  end

  defp register_time_peer_radio_hash_id(%Netwatch{time_peer_radio_hash_id: time_peer_radio_hash_id} = nw_struct) do
    Cache.put({:netwatch, time_peer_radio_hash_id}, 1)
    nw_struct
  end

  defp notify_dmrwatch_event_manager(%Netwatch{} = nw_struct) do
    :ok = GenEvent.sync_notify(:dmrwatch_event_manager, nw_struct)
    nw_struct
  end

  defp remove_nbsp(column) do
    String.replace(column, "&nbsp;", " ")
  end

  defp remove_whitespace(column) do
    String.strip(column)
  end

  defp convert_to_float(""), do: 0.0
  defp convert_to_float("Not avail."), do: 0.0
  defp convert_to_float("N/A"), do: 0.0
  defp convert_to_float(num) when is_float(num), do: num
  defp convert_to_float(num), do: String.to_float(num)

  defp convert_to_integer(""), do: 0
  defp convert_to_integer("Not avail."), do: 0
  defp convert_to_integer("N/A"), do: 0
  defp convert_to_integer(num) when is_integer(num), do: num
  defp convert_to_integer(num), do: String.to_integer(num)

  def parse_timestamp(ts) do
    # Sample : "03:48:38.471 Aug 5" -> "2014-08-05T03:48:38+0000"

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
