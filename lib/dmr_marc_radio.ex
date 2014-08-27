defmodule DmrMarcRadio do

  @moduledoc """
  Define a module and a Struct representing DMR-MARC subscriber radios.
  """

  require Logger

  defstruct radio_id: "",
            callsign: "",
            name: "",
            city: "",
            state: "",
            country: "",
            home_repeater: "",
            remarks: ""
end
