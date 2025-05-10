defmodule Dashboard.StockData.Cache do
  @moduledoc """
  Manages an ETS table for caching stock data.
  The table stores stock symbols as keys and maps of stock data as values.
  Example: {"AAPL", %{price: 150.00, timestamp: 1678886400000}}
  """
  require Logger

  @table_name :stock_data_cache

  @doc """
  Initializes the ETS table.
  This should be called once when the application starts, typically by a supervisor.
  Returns `:ok` if the table is created, or `{:error, {:already_started, pid}}` if it already exists.
  """
  def init() do
    table_pid = :ets.whereis(@table_name)

    if table_pid != :undefined do
      Logger.warning("ETS table #{@table_name} already exists with pid: #{inspect(table_pid)}.")
      {:error, {:already_started, table_pid}}
    else
      Logger.info("Initializing ETS table: #{@table_name}")
      # :ets.new returns the table identifier (tid) on success, or raises on error.
      # We wrap this to ensure :ok is returned on success as per typical init callbacks.
      try do
        :ets.new(@table_name, [:set, :public, :named_table, read_concurrency: true])
        :ok
      rescue
        e ->
          Logger.error("Failed to create ETS table #{@table_name}: #{inspect(e)}")
          reraise e, __STACKTRACE__
      end
    end
  end

  @doc """
  Puts stock data into the cache.
  Overwrites existing data for the symbol.
  """
  def put(symbol, data) when is_binary(symbol) and is_map(data) do
    :ets.insert(@table_name, {symbol, data})
  end

  @doc """
  Gets stock data for a given symbol from the cache.
  Returns `{:ok, data}` or `:not_found`.
  """
  def get(symbol) when is_binary(symbol) do
    case :ets.lookup(@table_name, symbol) do
      [{^symbol, data}] -> {:ok, data}
      [] -> :not_found
    end
  end

  @doc """
  Gets all stock data from the cache.
  Returns a list of `{symbol, data}` tuples.
  """
  def get_all_stocks() do
    :ets.tab2list(@table_name)
  end
end
