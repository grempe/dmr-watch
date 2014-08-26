defmodule NetwatchRegistry do

  @default_bucket :netwatch_registry

  @doc """
  Starts a new bucket.
  """
  def start_link do
    Agent.start_link(fn -> HashDict.new end, name: @default_bucket)
  end

  @doc """
  Gets a value from the `bucket` by `key`.
  """
  def get(bucket \\ @default_bucket, key) do
    if val = Agent.get(bucket, &HashDict.get(&1, key)) do
      {:ok, val}
    else
      {:error, nil}
    end
  end

  @doc """
  Puts the `value` for the given `key` in the `bucket`.
  """
  def put(bucket \\ @default_bucket, key, value) do
    Agent.update(bucket, &HashDict.put(&1, key, value))
  end

  def duplicate?(bucket \\ @default_bucket, key) do
    Agent.get(bucket, &HashDict.has_key?(&1, key))
  end

  def new?(key) do
    !duplicate?(key)
  end

  def keys(bucket \\ @default_bucket) do
    Agent.get(bucket, &HashDict.keys(&1))
  end

  @doc """
  Deletes the `value` for the given `key` in the `bucket`.
  """
  def delete(bucket \\ @default_bucket, key) do
    Agent.update(bucket, &HashDict.drop(&1, [key]))
  end

  @doc """
  Flush all `keys` in the `bucket` by iterating over each and deleting each.
  """
  def flush do
    keys
    |> Enum.map(&delete(&1))
  end

end
