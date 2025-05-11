defmodule Dashboard.StockData.CacheTest do
  use ExUnit.Case, async: true

  alias Dashboard.StockData.Cache

  describe "init/0" do
    setup do
      # Ensure table is deleted before each test in this describe block
      # This is important because :named_table ETS tables are global.
      if :ets.whereis(Cache.table_name()) != :undefined do
        :ets.delete(Cache.table_name())
      end
      :ok
    end

    test "initializes the ETS table successfully" do
      assert Cache.init() == :ok
      assert :ets.whereis(Cache.table_name()) != :undefined
      # Clean up after test (ensure it exists before deleting)
      if :ets.whereis(Cache.table_name()) != :undefined do
        :ets.delete(Cache.table_name())
      end
    end

    test "returns error and logs warning if table already exists" do
      # Initialize it once
      assert Cache.init() == :ok
      assert :ets.whereis(Cache.table_name()) != :undefined

      # Capture log to check warning
      assert ExUnit.CaptureLog.capture_log(fn ->
               assert {:error, {:already_started, tid}} = Cache.init()
               assert tid != :undefined # Check it's a valid table identifier, not necessarily a PID
             end) =~ "ETS table #{Cache.table_name()} already exists"

      # Clean up after test (ensure it exists before deleting)
      if :ets.whereis(Cache.table_name()) != :undefined do
        :ets.delete(Cache.table_name())
      end
    end
  end

  describe "data manipulation functions" do
    setup do
      # Ensure table is created and clean for these tests
      if :ets.whereis(Cache.table_name()) != :undefined do
        :ets.delete(Cache.table_name()) # Delete if exists from previous runs or other tests
      end
      assert Cache.init() == :ok

      on_exit(fn ->
        # Ensure the table is cleaned up after each test in this describe block
        if :ets.whereis(Cache.table_name()) != :undefined do
          :ets.delete(Cache.table_name())
        end
      end)

      :ok
    end

    test "put/2 inserts data and get/1 retrieves it" do
      assert Cache.put("AAPL", %{price: 150.00}) == :ok
      assert Cache.get("AAPL") == {:ok, %{price: 150.00}}
    end

    test "get/1 returns :not_found for non-existent symbol" do
      assert Cache.get("MSFT") == :not_found
    end

    test "put/2 overwrites existing data for a symbol" do
      Cache.put("AAPL", %{price: 150.00})
      assert Cache.put("AAPL", %{price: 151.00}) == :ok
      assert Cache.get("AAPL") == {:ok, %{price: 151.00}}
    end

    test "get_all_stocks/0 returns all data as a list of tuples" do
      Cache.put("AAPL", %{price: 150.00, data: "a"})
      Cache.put("MSFT", %{price: 300.00, data: "b"})

      all_stocks = Cache.get_all_stocks()
      assert length(all_stocks) == 2
      # Convert to Map for easier assertion of presence, as order is not guaranteed
      all_stocks_map = Map.new(all_stocks)
      assert all_stocks_map["AAPL"] == %{price: 150.00, data: "a"}
      assert all_stocks_map["MSFT"] == %{price: 300.00, data: "b"}
    end

    test "get_all_stocks/0 returns an empty list if cache is empty" do
      assert Cache.get_all_stocks() == []
    end
  end
end
