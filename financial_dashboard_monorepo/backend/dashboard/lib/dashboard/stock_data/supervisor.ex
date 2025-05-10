defmodule Dashboard.StockData.Supervisor do
  @moduledoc """
  Supervises stock data related processes, including the FinnhubClient
  and initializes the StockData.Cache.
  """
  use Supervisor
  require Logger

  alias Dashboard.StockData.Cache
  alias Dashboard.StockData.FinnhubClient

  def start_link(arg) do
    Supervisor.start_link(__MODULE__, arg, name: __MODULE__)
  end

  @impl true
  def init(_arg) do
    # Initialize the ETS cache table
    # This ensures the table exists before any process tries to access it.
    case Cache.init() do
      :ok ->
        Logger.info("StockData.Cache initialized successfully by StockData.Supervisor.")
      {:error, {:already_started, _pid}} ->
        Logger.warning("StockData.Cache ETS table already initialized.") # Changed Logger.warn to Logger.warning
      other_init_result ->
        Logger.error("StockData.Cache initialization failed: #{inspect(other_init_result)}")
        # Decide if this is a fatal error for the supervisor
        # For now, we'll let it continue, FinnhubClient might fail if cache is not up.
    end

    children = [
      FinnhubClient # Start the FinnhubClient GenServer
    ]

    Supervisor.init(children, strategy: :one_for_one)
  end
end
