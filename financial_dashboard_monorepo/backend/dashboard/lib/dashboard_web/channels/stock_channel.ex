defmodule DashboardWeb.StockChannel do
  use Phoenix.Channel
  require Logger
  alias Dashboard.StockData.Cache # Task 3.1: Access cache

  def join("stocks:lobby", _payload, socket) do
    Logger.info("Client joined stocks:lobby")
    # Task 3.1: Send initial data for all stocks upon join
    initial_data =
      Cache.get_all_stocks()
      |> Enum.map(fn {symbol, data} ->
        # Task 3.2: Include daily_change_percent and previous_close
        # data should now contain :session_open_price and :daily_change_percent from the cache
        %{
          symbol: symbol,
          price: Map.get(data, :price),
          timestamp: Map.get(data, :timestamp),
          previous_close: Map.get(data, :session_open_price), # This is our session_open_price
          daily_change_percent: Map.get(data, :daily_change_percent, 0.0),
          last_updated: Map.get(data, :last_updated)
        }
      end)

    send(self(), {:after_join, initial_data})
    {:ok, socket}
  end

  # Task 3.1: This handle_info is for sending initial data after join
  def handle_info({:after_join, initial_data}, socket) do
    push(socket, "initial_stocks", %{stocks: initial_data})
    Logger.debug("Sent initial_stocks to client: #{inspect(initial_data)}")
    {:noreply, socket}
  end

  # Handle incoming "ping" event from the client
  def handle_in("ping", payload, socket) do
    Logger.info("Received ping with payload: #{inspect(payload)}")
    # Send a "pong" event back to the client
    push(socket, "pong", %{message: "pong", original_payload: payload})
    {:noreply, socket}
  end

  # Handle other messages if needed
  def handle_in(event, payload, socket) do
    Logger.info("Unhandled event: #{event} with payload: #{inspect(payload)}")
    {:noreply, socket}
  end
end
