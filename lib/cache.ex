defmodule Cache do

  require Logger
  use Timex

  @default_bucket :dmr_watch_cache
  @default_cache_time_in_seconds 86400   # 86400 Seconds = 24 Hours

  @doc """
  Starts a new bucket.
  """
  def start_link do
    Agent.start_link(fn -> HashDict.new end, name: @default_bucket)
  end

  @doc """
  Gets a value from the `bucket` by `key`
  """
  def get(bucket \\ @default_bucket, {namespace, key}) when is_atom(namespace) do
    case Agent.get(bucket, &HashDict.get(&1, key)) do
      {value, _time} ->
        {:ok, value}
      _ ->
        #Logger.debug "Cache.get : cache miss : #{{namespace, key}}"
        {:ok, :not_found}
    end
  end

  @doc """
  Puts the `value` for the given `key` in the `bucket` where `key` must be a `{namespace, key}` tuple.
  """
  def put(bucket \\ @default_bucket, {namespace, key}, value) when is_atom(namespace) do
    Agent.update(bucket, &HashDict.put(&1, {namespace, key}, {value, Timex.Time.now}))
  end

  @doc """
  Deletes the `value` for the given `key` in the `bucket` where `key` must be a `{namespace, key}` tuple.
  """
  def delete(bucket \\ @default_bucket, {namespace, key}) when is_atom(namespace) do
    Agent.update(bucket, &HashDict.drop(&1, [{namespace, key}]))
  end

  @doc """
  List all `keys` in the `bucket` where each `key` returned is a `{namespace, key}` tuple.
  """
  def keys(bucket \\ @default_bucket) do
    Agent.get(bucket, &HashDict.keys(&1))
  end

  @doc """
  Delete all stale `keys` in the `bucket` by retrieving each and comparing
  to the @default_cache_time_in_seconds.
  """
  def prune do
    keys
    |> Enum.map(&prune(&1))
    :ok
  end

  def prune(bucket \\ @default_bucket, {namespace, key}) when is_atom(namespace) do
    case Agent.get(bucket, &HashDict.get(&1, {namespace, key})) do
      {_value, time} ->
        if Timex.Time.diff(Timex.Time.now, time, :secs) > @default_cache_time_in_seconds do
          Logger.debug "Cache.prune : deleting old key : #{{namespace, key}} : cached #{Timex.Time.elapsed(time, :secs)} seconds ago."
          delete({namespace, key})
        end
    end
  end

  @doc """
  Flush all `keys` in the `bucket` by iterating over each and deleting.
  """
  def flush do
    keys
    |> Enum.map(&delete(&1))
    :ok
  end

  def has_key?(bucket \\ @default_bucket, {namespace, key}) when is_atom(namespace) do
    Agent.get(bucket, &HashDict.has_key?(&1, {namespace, key}))
  end

  def new?({namespace, key}) when is_atom(namespace) do
    !has_key?({namespace, key})
  end

end
