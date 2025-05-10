defmodule Dashboard.StockData.FinnhubWebSocketClient do
  @moduledoc """
  WebSockex client implementation for the Finnhub WebSocket API.
  """
  use WebSockex
  require Logger

  @impl true
  def handle_connect(_conn, state) do
    Logger.debug("FinnhubWebSocketClient: WebSocket connected to Finnhub.")
    send(state.parent, {:socket_connected, self()})
    {:ok, state}
  end

  # This callback is invoked when the socket is disconnected for any reason.
  # It's called before terminate/2 if the process is also stopping.
  @impl true
  def handle_disconnect(reason, state) do
    Logger.warning("FinnhubWebSocketClient: handle_disconnect/2 called. Reason: #{inspect(reason)}")
    # Signal this client process to stop. terminate/2 will then be called to notify the parent.
    {:stop, reason, state}
  end

  @impl true
  def handle_frame(frame, state) do
    send(state.parent, {:socket_frame, self(), frame})
    {:ok, state}
  end

  @impl true
  def handle_ping(_ping_frame, state) do # Prefixed with _
    Logger.debug("FinnhubWebSocketClient: Received Ping from Finnhub, WebSockex will auto-reply with Pong.")
    # WebSockex handles Pongs automatically.
    {:ok, state}
  end

  @impl true
  def handle_pong(_pong_frame, state) do # Prefixed with _
    Logger.debug("FinnhubWebSocketClient: Received Pong from Finnhub.")
    {:ok, state}
  end

  @impl true
  def terminate(reason, state) do
    Logger.warning("FinnhubWebSocketClient: Terminating. Reason: #{inspect(reason)}")
    # Inform the parent (FinnhubClient) about the termination.
    # Distinguish between a normal stop and an error.
    message_to_parent =
      case reason do
        :normal -> {:socket_closed, self()}
        :shutdown -> {:socket_closed, self()}
        {:shutdown, _} -> {:socket_closed, self()}
        # Consider {:remote, :closed} as a potentially recoverable scenario, but still an error from client's perspective
        # if it wasn't initiated by us. For Finnhub, this often means they closed it.
        _error_reason -> {:socket_error, self(), reason}
      end
    send(state.parent, message_to_parent)
    :ok
  end
end
