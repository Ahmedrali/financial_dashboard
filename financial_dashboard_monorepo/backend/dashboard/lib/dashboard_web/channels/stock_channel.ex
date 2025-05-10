defmodule DashboardWeb.StockChannel do
  use Phoenix.Channel
  require Logger

  def join("stocks:lobby", _payload, socket) do
    Logger.info("Client joined stocks:lobby")
    {:ok, socket}
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
