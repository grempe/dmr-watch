defmodule DmrMarcRadioCache do

  require Logger
  use Timex

  @default_bucket :dmr_marc_radio_cache
  @default_cache_time_in_hours 24

  @doc """
  Starts a new bucket.
  """
  def start_link do
    Agent.start_link(fn -> HashDict.new end, name: @default_bucket)
  end

  @doc """
  Gets a value from the `bucket` by `key`
  """
  def get(bucket \\ @default_bucket, key) do
    case Agent.get(bucket, &HashDict.get(&1, key)) do
      {value, time} ->
        #Logger.debug "DmrMarcRadioCache.get : cache hit : #{key} : cached #{Timex.Time.elapsed(time, :secs)} seconds ago."
        {:ok, value}
      _ ->
        #Logger.debug "DmrMarcRadioCache.get : cache miss : #{key}"
        {:ok, :not_found}
    end
  end

  @doc """
  Puts the `value` for the given `key` in the `bucket`.
  """
  def put(bucket \\ @default_bucket, key, value) do
    Agent.update(bucket, &HashDict.put(&1, key, {value, Timex.Time.now}))
  end

  @doc """
  Deletes the `value` for the given `key` in the `bucket`.
  """
  def delete(bucket \\ @default_bucket, key) do
    Agent.update(bucket, &HashDict.drop(&1, [key]))
  end

  @doc """
  List all `keys` in the `bucket`.
  """
  def keys(bucket \\ @default_bucket) do
    Agent.get(bucket, &HashDict.keys(&1))
  end

  @doc """
  Delete all stale `keys` in the `bucket` by retrieving each and comparing
  to the @default_cache_time_in_hours.
  """
  def prune() do
    keys
    |> Enum.map(&prune(&1))
    :ok
  end

  def prune(bucket \\ @default_bucket, key) do
    case Agent.get(bucket, &HashDict.get(&1, key)) do
      {value, time} ->
        if Timex.Time.diff(Timex.Time.now, time, :hours) > @default_cache_time_in_hours do
          Logger.debug "DmrMarcRadioCache.prune : deleting old key : #{key} : cached #{Timex.Time.elapsed(time, :secs)} seconds ago."
          delete(key)
        end
    end
  end

  @doc """
  Prune periodically.
  """
  def prune_every(frequency_in_ms \\ 60_000) do
    :ok = prune
    :timer.sleep(frequency_in_ms)
    prune_every(frequency_in_ms)
  end

  @doc """
  Flush all `keys` in the `bucket` by iterating over each and deleting.
  """
  def flush() do
    keys
    |> Enum.map(&delete(&1))
    :ok
  end

end
