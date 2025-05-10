defmodule DashboardWeb.UserSocket do
  use Phoenix.Socket

  # Channels
  channel "stocks:lobby", DashboardWeb.StockChannel

  # Transports
  # transport :longpoll, Phoenix.Transports.LongPoll # We can disable longpoll if only using websockets
  # WebSocket transport is configured in the endpoint and this line is deprecated.

  # Connect is called when a connection is established.
  # It is often used for authentication and checking connection parameters.
  def connect(_params, socket, _connect_info) do
    # Allow all connections for now
    {:ok, socket}
  end

  # id is called when a connection is established.
  # It should return a unique ID for the socket.
  # For an unauthenticated socket, you can use `nil`.
  def id(_socket), do: nil
end
