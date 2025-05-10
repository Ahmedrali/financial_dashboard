defmodule Dashboard.StockData.FinnhubClient do
  @moduledoc """
  A GenServer responsible for connecting to the Finnhub WebSocket API,
  subscribing to stock symbols, and processing incoming trade data.
  """
  use GenServer
  require Logger

  alias Dashboard.StockData.Cache

  @finnhub_ws_url "wss://ws.finnhub.io"
  @initial_stocks_to_subscribe ["BINANCE:BTCUSDT", "AAPL", "MSFT", "NVDA", "GOOGL", "JPM", "BAC", "V", "AMZN", "WMT", "MCD"] # Task 3.4
  @max_reconnect_attempts 10
  @base_reconnect_delay_ms 5_000 # Initial delay: 5 seconds
  @max_reconnect_delay_ms 60_000 # Max delay: 1 minute

  # Client API

  def start_link(opts) do
    GenServer.start_link(__MODULE__, opts, name: __MODULE__)
  end

  # GenServer Callbacks

  @impl true
  def init(_opts) do
    api_key = Application.fetch_env!(:dashboard, :finnhub_api_key)
    initial_state = %{ # Renamed to initial_state for clarity
      api_key: api_key,
      socket: nil,
      stocks_to_subscribe: @initial_stocks_to_subscribe,
      reconnect_attempts: 0
    }
    Logger.info("FinnhubClient starting...")
    resulting_state = connect_to_finnhub(initial_state) # connect_to_finnhub now returns the state
    {:ok, resulting_state} # Ensure init returns {:ok, state}
  end

  @impl true
  def handle_info({:socket_connected, connected_socket_pid}, state) do
    # This message comes from FinnhubWebSocketClient.handle_connect
    # Ensure this message is for the current socket we are managing (if one was already stored and matches)
    # or accept it if we don't have one (initial connection) or if it matches the one we just started.
    if state.socket == nil || state.socket == connected_socket_pid do
      Logger.info("Successfully connected to Finnhub WebSocket (PID: #{inspect(connected_socket_pid)}).")
      # Update socket PID in state and reset reconnect_attempts.
      new_state = %{state | socket: connected_socket_pid, reconnect_attempts: 0}
      subscribe_to_stocks(connected_socket_pid, new_state.stocks_to_subscribe)
      {:noreply, new_state}
    else
      Logger.warning("Received :socket_connected for unexpected socket PID #{inspect(connected_socket_pid)}. Current socket: #{inspect(state.socket)}. Ignoring.")
      {:noreply, state}
    end
  end

  @impl true
  def handle_info({:socket_error, socket_pid, reason}, state) do
    # This message comes from FinnhubWebSocketClient.terminate
    if state.socket == socket_pid do
      Logger.error("Finnhub WebSocket connection error (PID: #{socket_pid}): #{inspect(reason)}")
      schedule_reconnect(state) # schedule_reconnect will set state.socket to nil
    else
      Logger.warning("Received :socket_error for an old/unexpected socket PID #{socket_pid}. Current: #{state.socket}. Ignoring.")
      {:noreply, state}
    end
  end

  @impl true
  def handle_info({:socket_closed, socket_pid}, state) do
    # This message comes from FinnhubWebSocketClient.terminate
    if state.socket == socket_pid do
      Logger.warning("Finnhub WebSocket connection closed (PID: #{socket_pid}).")
      schedule_reconnect(state) # schedule_reconnect will set state.socket to nil
    else
      Logger.warning("Received :socket_closed for an old/unexpected socket PID #{socket_pid}. Current: #{state.socket}. Ignoring.")
      {:noreply, state}
    end
  end

  @impl true
  def handle_info({:socket_frame, socket_pid, frame}, state) do
    # This message comes from FinnhubWebSocketClient.handle_frame
    if state.socket == socket_pid do
      # Frame can be {:text, data} or {:binary, data}
      # Finnhub sends JSON text frames
      case frame do
        {:text, payload} ->
          handle_finnhub_message(payload, state)
        {:ping, _payload} ->
          # WebSockex handles pong automatically
          Logger.debug("Received WebSocket ping from Finnhub.")
        {:pong, _payload} ->
          Logger.debug("Received WebSocket pong from Finnhub.")
        _other_frame ->
          Logger.warning("Received unexpected WebSocket frame: #{inspect(frame)}")
      end
    end
    {:noreply, state}
  end

  @impl true
  def handle_info(:reconnect, state) do
    Logger.info("Attempting to reconnect to Finnhub WebSocket...")
    new_state = connect_to_finnhub(state) # connect_to_finnhub now returns the state
    {:noreply, new_state} # Wrap state in {:noreply, ...} for handle_info
  end

  @impl true
  def handle_info(unhandled_message, state) do # Renamed _unhandled_message
    Logger.warning("FinnhubClient received unhandled message: #{inspect(unhandled_message)}")
    {:noreply, state}
  end

  # Private helpers

  defp connect_to_finnhub(state) do
    if state.reconnect_attempts >= @max_reconnect_attempts do
      Logger.error("Max reconnect attempts reached for Finnhub. Giving up. Current attempts: #{state.reconnect_attempts}")
      # Return the state indicating it has given up.
      %{state | socket: nil} # No change to reconnect_attempts, it's already at/over max.
    else
      url = @finnhub_ws_url <> "?token=#{state.api_key}"
      # Log the attempt number using state.reconnect_attempts + 1 as it's the current attempt being made.
      Logger.info("Connecting to Finnhub: #{url} (Attempt ##{state.reconnect_attempts + 1})")

      case WebSockex.start_link(url, Dashboard.StockData.FinnhubWebSocketClient, %{parent: self()}) do
        {:ok, socket_pid} ->
          # WebSockex process started successfully.
          # Store its PID. The actual :socket_connected message will arrive from
          # the FinnhubWebSocketClient.handle_connect callback.
          Logger.debug("FinnhubClient: WebSockex process #{inspect(socket_pid)} started. Waiting for its :socket_connected message.")
          %{state | socket: socket_pid} # Store the PID of the client process
        {:error, reason} ->
          # This attempt (state.reconnect_attempts + 1) has failed.
          failed_attempts_count = state.reconnect_attempts + 1
          Logger.error(
            "Failed to start Finnhub WebSocket connection process (failure ##{failed_attempts_count}): #{inspect(reason)}"
          )

          if failed_attempts_count >= @max_reconnect_attempts do
            Logger.error(
              "Max reconnect attempts (#{failed_attempts_count}) reached after failure in connect_to_finnhub. Giving up."
            )
            %{state | socket: nil, reconnect_attempts: failed_attempts_count}
          else
            delay_ms = calculate_reconnect_delay(failed_attempts_count)
            Logger.info(
              "Scheduling Finnhub reconnect (after #{failed_attempts_count} failures) in #{delay_ms}ms."
            )
            Process.send_after(self(), :reconnect, delay_ms)
            %{state | socket: nil, reconnect_attempts: failed_attempts_count}
          end
      end
    end
  end

  defp schedule_reconnect(state) do
    # A previously active connection failed, or a scheduled reconnect is being processed.
    # state.reconnect_attempts already reflects the number of failures in the current sequence.
    # This specific call to schedule_reconnect means one more failure in the sequence.
    current_sequence_failures = state.reconnect_attempts + 1

    if current_sequence_failures > @max_reconnect_attempts do
      Logger.error(
        "Max reconnect attempts reached (#{current_sequence_failures - 1} retries failed). Not scheduling further retries."
      )
      {:noreply, %{state | socket: nil, reconnect_attempts: current_sequence_failures}}
    else
      delay_ms = calculate_reconnect_delay(current_sequence_failures)
      Logger.info(
        "Connection lost/failed. Scheduling Finnhub reconnect (failure ##{current_sequence_failures} in sequence) in #{delay_ms}ms."
      )
      Process.send_after(self(), :reconnect, delay_ms)
      {:noreply, %{state | socket: nil, reconnect_attempts: current_sequence_failures}}
    end
  end

  defp calculate_reconnect_delay(num_failures_so_far) do
    # num_failures_so_far is 1-based (1st failure, 2nd failure, etc.)
    # Delay = Base * 2^(failures - 1), capped by MaxDelay
    delay_factor = :math.pow(2, num_failures_so_far - 1)
    calculated_delay = round(@base_reconnect_delay_ms * delay_factor)
    min(calculated_delay, @max_reconnect_delay_ms)
  end

  defp subscribe_to_stocks(socket, stocks) do
    # Add rate limiting by using Process.sleep between subscription requests
    # Finnhub has a rate limit of 30 API calls per second
    Enum.each(stocks, fn symbol ->
      subscription_message = Jason.encode!(%{type: "subscribe", symbol: symbol})
      Logger.info("Subscribing to #{symbol} on Finnhub.")
      case WebSockex.send_frame(socket, {:text, subscription_message}) do
        :ok ->
          Logger.debug("Sent subscription for #{symbol}")
          # Increase delay to be more conservative, e.g., 1 second per subscription
          Process.sleep(1000) # 1000ms = 1 second
        {:error, reason} -> Logger.error("Failed to send subscription for #{symbol}: #{inspect(reason)}")
      end
    end)
  end

  defp handle_finnhub_message(payload, _state) do
    case Jason.decode(payload) do
      {:ok, %{"type" => "trade", "data" => trades}} when is_list(trades) ->
        Enum.each(trades, fn trade_data ->
          # Example trade_data: %{"p" => 150.0, "s" => "AAPL", "t" => 1678886400000, "v" => 100}
          # p: price, s: symbol, t: timestamp (unix ms), v: volume
          symbol = trade_data["s"]
          price = trade_data["p"]
          timestamp = trade_data["t"]

          if symbol && price && timestamp do
            # Retrieve existing data to get session_open_price or set it
            cached_data =
              case Cache.get(symbol) do
                {:ok, data} -> data
                :not_found -> %{} # No data yet for this symbol in this session
              end

            session_open_price = Map.get(cached_data, :session_open_price, price) # Use current price if first time

            daily_change_percent =
              if session_open_price != 0 and session_open_price != nil do
                # Ensure session_open_price is a number for calculation
                sop_float = if is_number(session_open_price), do: session_open_price, else: price
                ((price - sop_float) / sop_float) * 100
                |> Float.round(4) # Round to 4 decimal places
              else
                0.0 # Default to 0 if session_open_price is zero or nil
              end

            updated_cache_data = %{
              price: price,
              timestamp: timestamp,
              session_open_price: session_open_price, # This is our "previous_close" for the session
              daily_change_percent: daily_change_percent,
              last_updated: DateTime.utc_now()
            }
            Cache.put(symbol, updated_cache_data)
            Logger.info(
              "[Finnhub Trade] Symbol: #{symbol}, Price: #{price}, SOP: #{session_open_price}, Change %: #{daily_change_percent}"
            )

            # Task 3.1 & 3.2: Broadcast stock update with new fields
            broadcast_payload = %{
              symbol: symbol,
              price: price,
              timestamp: timestamp,
              previous_close: session_open_price, # Using session_open_price as previous_close
              daily_change_percent: daily_change_percent
            }
            DashboardWeb.Endpoint.broadcast("stocks:lobby", "stock_update", broadcast_payload)
            Logger.debug("Broadcasted stock_update for #{symbol}: #{inspect(broadcast_payload)}")
          else
            Logger.warning("Received trade data with missing fields: #{inspect(trade_data)}")
          end
        end)

      {:ok, %{"type" => "ping"}} ->
        # Finnhub might send pings this way too, though WebSockex might handle WebSocket level pings.
        Logger.debug("Received Finnhub application-level ping: #{payload}")
        # No action needed, Finnhub expects WebSocket level pong if it sent a WebSocket ping.

      {:ok, %{"type" => "subscribe", "symbol" => symbol}} ->
        # This is an acknowledgement from Finnhub for our subscription.
        Logger.info("Successfully subscribed to symbol: #{symbol} (acknowledged by Finnhub).")

      {:ok, other_message} ->
        Logger.info("Received other Finnhub message: #{inspect(other_message)}")

      {:error, reason} ->
        Logger.error("Failed to decode Finnhub JSON payload: #{inspect(reason)}. Payload: #{payload}")
    end
  end
end
