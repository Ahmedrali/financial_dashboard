Implementation Plan                                                                                                                                                                                              

Here is a detailed implementation plan for the Real-Time Financial Dashboard project:                                                                                                                            

Introduction                                                                                                                                                                                                     

This plan outlines the strategy for developing a real-time financial dashboard using Elixir/Phoenix for the backend and Svelte for the frontend. The application will connect to the Finnhub WebSocket API to    
display live stock market data for a predefined portfolio. This plan covers monorepo setup, backend and frontend architecture, milestone breakdown, testing, and other critical aspects of development, aligning 
with the project requirements and grading criteria.                                                                                                                                                              

1. Monorepo Structure                                                                                                                                                                                            

We will use a monorepo to manage both the Elixir backend and Svelte frontend code.                                                                                                                               

 • Directory Structure: Create the following top-level directory structure:                                                                                                                                      
                                                                                                                                                                                                                 
   financial_dashboard_monorepo/                                                                                                                                                                                 
   ├── backend/            # Phoenix application                                                                                                                                                                 
   │   ├── apps/                                                                                                                                                                                                 
   │   │   └── dashboard/      # Main Phoenix app                                                                                                                                                                
   │   │   └── dashboard_web/  # Phoenix web interface (controllers, views, channels)                                                                                                                            
   │   ├── config/                                                                                                                                                                                               
   │   ├── deps/                                                                                                                                                                                                 
   │   ├── lib/                                                                                                                                                                                                  
   │   ├── priv/                                                                                                                                                                                                 
   │   ├── test/                                                                                                                                                                                                 
   │   └── mix.exs                                                                                                                                                                                               
   ├── frontend/           # Svelte application                                                                                                                                                                  
   │   ├── public/                                                                                                                                                                                               
   │   ├── src/                                                                                                                                                                                                  
   │   │   ├── components/ # Svelte components                                                                                                                                                                   
   │   │   ├── stores/     # Svelte stores                                                                                                                                                                       
   │   │   ├── services/   # WebSocket service, etc.                                                                                                                                                             
   │   │   └── main.js     # Or main.ts if using TypeScript                                                                                                                                                      
   │   ├── package.json                                                                                                                                                                                          
   │   ├── svelte.config.js                                                                                                                                                                                      
   │   └── vite.config.js  # Or rollup.config.js                                                                                                                                                                 
   ├── .gitignore                                                                                                                                                                                                
   └── README.md                                                                                                                                                                                                 
                                                                                                                                                                                                                 
 • Configuration for Shared Dependencies:                                                                                                                                                                        
    • No direct shared dependencies are anticipated between Elixir and Svelte that would require complex linking (e.g., via npm link or Yarn workspaces at the root for shared JS code, which is not the case    
      here).                                                                                                                                                                                                     
    • Communication will be via WebSockets.                                                                                                                                                                      
    • A root README.md will explain how to run both backend and frontend.                                                                                                                                        
 • Build Process Integration:                                                                                                                                                                                    
    • Backend: Standard Mix commands (mix deps.get, mix compile, mix phx.server).                                                                                                                                
    • Frontend: Standard npm/yarn/pnpm commands (npm install, npm run dev, npm run build).                                                                                                                       
    • For production, the Svelte app will be built into static assets, which could be served by Phoenix if desired, but for simplicity and clear separation, we'll run them as distinct processes during         
      development. The Phoenix backend will primarily serve the API endpoint for WebSocket connections.                                                                                                          
 • Development Workflow:                                                                                                                                                                                         
    1 Navigate to backend/ and run the Phoenix server.                                                                                                                                                           
    2 Navigate to frontend/ and run the Svelte development server.                                                                                                                                               
    3 Develop backend and frontend features in their respective directories.                                                                                                                                     
    4 Ensure the .gitignore at the root level ignores backend/deps, backend/_build, frontend/node_modules, frontend/dist (or public/build depending on Svelte setup).                                            

2. Elixir/Phoenix Backend                                                                                                                                                                                        

 • Supervision Tree Structure:                                                                                                                                                                                   
    • Dashboard.Application (in backend/apps/dashboard/lib/dashboard/application.ex):                                                                                                                            
       • Main application supervisor.                                                                                                                                                                            
       • Supervises:                                                                                                                                                                                             
          • The Phoenix Endpoint (DashboardWeb.Endpoint).                                                                                                                                                        
          • A Dashboard.StockData.Supervisor (DynamicSupervisor or Supervisor):                                                                                                                                  
             • This supervisor will manage one Dashboard.StockData.FinnhubClient GenServer per stock symbol, or a single GenServer managing multiple WebSocket connections/subscriptions if the API allows and   
               it's more efficient. Given Finnhub's model, one client GenServer managing one WebSocket connection to Finnhub, subscribing to multiple stocks, is likely optimal. Let's plan for one FinnhubClient
               GenServer.                                                                                                                                                                                        
             • This supervisor will also manage Dashboard.StockData.Cache (an ETS table owner/manager, could be a GenServer or just functions using a named table).                                              
    • Design Choice: A dedicated supervisor for data-related processes (Dashboard.StockData.Supervisor) promotes separation of concerns and resilience. The FinnhubClient GenServer will handle the complexities 
      of the WebSocket connection to Finnhub.                                                                                                                                                                    
 • GenServers for Finnhub WebSocket (Dashboard.StockData.FinnhubClient):                                                                                                                                         
    • File Path: backend/apps/dashboard/lib/dashboard/stock_data/finnhub_client.ex                                                                                                                               
    • Responsibilities:                                                                                                                                                                                          
       • Establish and maintain a WebSocket connection to Finnhub (wss://ws.finnhub.io?token=YOUR_API_KEY).                                                                                                      
       • Handle authentication (API token in URL).                                                                                                                                                               
       • Subscribe to trade updates for the required stock symbols: AAPL, MSFT, NVDA, GOOGL, JPM, BAC, V, AMZN, WMT, MCD.                                                                                        
       • Receive messages from Finnhub, parse them.                                                                                                                                                              
       • Store latest price data in ETS.                                                                                                                                                                         
       • Broadcast updates through Phoenix Channels.                                                                                                                                                             
    • Error Handling:                                                                                                                                                                                            
       • Implement handle_info({:gun_ws_error, _conn_pid, reason}, state) or equivalent for your WebSocket client library (e.g., websockex, gun).                                                                
       • Implement reconnection logic with exponential backoff.                                                                                                                                                  
       • Supervised by Dashboard.StockData.Supervisor to be restarted if it crashes.                                                                                                                             
    • Function Signatures (Illustrative):                                                                                                                                                                        
                                                                                                                                                                                                                 
      defmodule Dashboard.StockData.FinnhubClient do                                                                                                                                                             
        use GenServer                                                                                                                                                                                            
                                                                                                                                                                                                                 
        def start_link(opts) do                                                                                                                                                                                  
          GenServer.start_link(__MODULE__, opts, name: __MODULE__)                                                                                                                                               
        end                                                                                                                                                                                                      
                                                                                                                                                                                                                 
        @impl true                                                                                                                                                                                               
        def init(opts) do                                                                                                                                                                                        
          # Get API key from config                                                                                                                                                                              
          # Connect to Finnhub WebSocket                                                                                                                                                                         
          # Subscribe to initial stocks                                                                                                                                                                          
          # Schedule periodic check/reconnect if needed                                                                                                                                                          
        end                                                                                                                                                                                                      
                                                                                                                                                                                                                 
        # WebSocket message handlers (e.g., using :gun or :websockex callbacks)                                                                                                                                  
        # handle_info({:gun_ws, conn_pid, {:text, frame_content}}, state)                                                                                                                                        
        # handle_info({:gun_down, conn_pid, _protocol, _reason, _killed_by_us}, state)                                                                                                                           
                                                                                                                                                                                                                 
        # Internal messages for managing subscriptions if dynamic                                                                                                                                                
      end                                                                                                                                                                                                        
                                                                                                                                                                                                                 
 • ETS for Data Caching (Dashboard.StockData.Cache):                                                                                                                                                             
    • Table Name: :stock_data_cache                                                                                                                                                                              
    • Structure: Key-value store, where key is the stock symbol (e.g., "AAPL") and value is a map like %{price: 150.00, timestamp: <timestamp>, daily_change_percent: 0.5, previous_close: 149.25}.              
    • Implementation:                                                                                                                                                                                            
       • Create a module Dashboard.StockData.Cache (backend/apps/dashboard/lib/dashboard/stock_data/cache.ex).                                                                                                   
       • Initialize the ETS table in Dashboard.Application.start/2 or by the FinnhubClient GenServer.                                                                                                            
                                                                                                                                                                                                                 
      defmodule Dashboard.StockData.Cache do                                                                                                                                                                     
        @table_name :stock_data_cache                                                                                                                                                                            
                                                                                                                                                                                                                 
        def init() do                                                                                                                                                                                            
          :ets.new(@table_name, [:set, :public, :named_table, read_concurrency: true])                                                                                                                           
        end                                                                                                                                                                                                      
                                                                                                                                                                                                                 
        def put(symbol, data) do                                                                                                                                                                                 
          :ets.insert(@table_name, {symbol, data})                                                                                                                                                               
        end                                                                                                                                                                                                      
                                                                                                                                                                                                                 
        def get(symbol) do                                                                                                                                                                                       
          case :ets.lookup(@table_name, symbol) do                                                                                                                                                               
            [{^symbol, data}] -> {:ok, data}                                                                                                                                                                     
            [] -> :not_found                                                                                                                                                                                     
          end                                                                                                                                                                                                    
        end                                                                                                                                                                                                      
                                                                                                                                                                                                                 
        def get_all_stocks() do                                                                                                                                                                                  
          :ets.tab2list(@table_name) # Or use :ets.select for specific fields                                                                                                                                    
        end                                                                                                                                                                                                      
      end                                                                                                                                                                                                        
                                                                                                                                                                                                                 
    • The FinnhubClient will write to this ETS table. Phoenix Channels will read from it.                                                                                                                        
 • Phoenix Channels for Frontend Communication (DashboardWeb.StockChannel):                                                                                                                                      
    • File Path: backend/apps/dashboard_web/lib/dashboard_web/channels/stock_channel.ex                                                                                                                          
    • Channel Route: socket "/socket", DashboardWeb.UserSocket, websocket: [connect_info: [:session]] (in endpoint.ex)                                                                                           
    • Topic: "stocks:lobby" or similar for all stock updates.                                                                                                                                                    
    • Implementation:                                                                                                                                                                                            
                                                                                                                                                                                                                 
      defmodule DashboardWeb.StockChannel do                                                                                                                                                                     
        use Phoenix.Channel                                                                                                                                                                                      
                                                                                                                                                                                                                 
        def join("stocks:lobby", _payload, socket) do                                                                                                                                                            
          # Send initial data for all stocks upon join                                                                                                                                                           
          initial_data = Dashboard.StockData.Cache.get_all_stocks()                                                                                                                                              
                         |> Enum.map(fn {symbol, data} -> format_stock_update(symbol, data) end)                                                                                                                 
          # Consider fetching previous day's close here if not in cache or needs to be fresh                                                                                                                     
          send(self(), {:after_join, initial_data})                                                                                                                                                              
          {:ok, socket}                                                                                                                                                                                          
        end                                                                                                                                                                                                      
                                                                                                                                                                                                                 
        # This handle_info is for sending initial data after join to avoid race conditions                                                                                                                       
        def handle_info({:after_join, initial_data}, socket) do                                                                                                                                                  
          push(socket, "initial_stocks", %{stocks: initial_data})                                                                                                                                                
          {:noreply, socket}                                                                                                                                                                                     
        end                                                                                                                                                                                                      
                                                                                                                                                                                                                 
        # No handle_in needed if frontend only listens                                                                                                                                                           
        # Broadcasts will be sent from elsewhere (e.g., FinnhubClient via Endpoint)                                                                                                                              
      end                                                                                                                                                                                                        
                                                                                                                                                                                                                 
    • FinnhubClient will use DashboardWeb.Endpoint.broadcast("stocks:lobby", "stock_update", %{symbol: "AAPL", price: ..., ...}) to send updates.                                                                
    • Authentication: For this project, channel authentication is not strictly required beyond basic Phoenix setup. If it were, UserSocket.connect/3 would handle it.                                            
 • Error Handling and Reconnection (Finnhub & Phoenix Channels):                                                                                                                                                 
    • Finnhub: FinnhubClient GenServer handles WebSocket errors, retries connection with backoff. Supervised for crashes.                                                                                        
    • Phoenix Channels: Phoenix handles client disconnects/reconnects robustly. Ensure frontend Svelte client also has reconnection logic.                                                                       
 • Idiomatic Elixir Patterns:                                                                                                                                                                                    
    • Pattern Matching: Extensively in function heads and case statements for message parsing and state management.                                                                                              
    • Supervision Trees: For fault tolerance.                                                                                                                                                                    
    • GenServers: For stateful processes and managing external connections.                                                                                                                                      
    • Comprehensions: For data transformation.                                                                                                                                                                   
    • with statements: For handling multiple steps that can fail.                                                                                                                                                
    • PubSub: Phoenix.PubSub can be used directly by FinnhubClient to publish updates, and StockChannel can subscribe, or use Endpoint.broadcast. Endpoint.broadcast is simpler for this scale.                  

3. Svelte Frontend                                                                                                                                                                                               

 • Component Architecture:                                                                                                                                                                                       
    • App.svelte: Main application shell.                                                                                                                                                                        
    • Dashboard.svelte: Main container for all dashboard elements.                                                                                                                                               
       • StockCard.svelte: Displays data for a single stock (price, change, chart).                                                                                                                              
       • PortfolioSummary.svelte: Displays summary for the entire portfolio.                                                                                                                                     
       • StockChart.svelte: Simple line chart component (can be part of StockCard.svelte or separate).                                                                                                           
    • Justification: This component structure promotes reusability (StockCard) and separation of concerns.                                                                                                       
 • Store Implementation (Svelte Stores):                                                                                                                                                                         
    • File Path: frontend/src/stores/stockStore.js (or .ts)                                                                                                                                                      
    • Purpose: Manage real-time stock data, connection status.                                                                                                                                                   
    • Implementation:                                                                                                                                                                                            
                                                                                                                                                                                                                 
      // frontend/src/stores/stockStore.js                                                                                                                                                                       
      import { writable } from 'svelte/store';                                                                                                                                                                   
                                                                                                                                                                                                                 
      export const stocks = writable({}); // e.g., { AAPL: { price: 150, change: 0.5, history: [] }, ... }                                                                                                       
      export const connectionStatus = writable('disconnected'); // 'connecting', 'connected', 'error'                                                                                                            
      export const portfolioSummary = writable({ totalValue: 0, overallChange: 0 }); // Simplified                                                                                                               
                                                                                                                                                                                                                 
    • A service module will interact with Phoenix Channels and update these stores.                                                                                                                              
 • WebSocket Connection (via Phoenix Channels Client):                                                                                                                                                           
    • File Path: frontend/src/services/phoenixSocket.js                                                                                                                                                          
    • Library: phoenix npm package.                                                                                                                                                                              
    • Implementation:                                                                                                                                                                                            
                                                                                                                                                                                                                 
      // frontend/src/services/phoenixSocket.js                                                                                                                                                                  
      import { Socket } from 'phoenix';                                                                                                                                                                          
      import { stocks, connectionStatus } from '../stores/stockStore.js';                                                                                                                                        
                                                                                                                                                                                                                 
      let socket;                                                                                                                                                                                                
      let channel;                                                                                                                                                                                               
                                                                                                                                                                                                                 
      const API_URL = 'ws://localhost:4000/socket'; // Or from .env                                                                                                                                              
                                                                                                                                                                                                                 
      export function connectToSocket() {                                                                                                                                                                        
        if (socket) return;                                                                                                                                                                                      
                                                                                                                                                                                                                 
        connectionStatus.set('connecting');                                                                                                                                                                      
        socket = new Socket(API_URL, { params: {} /* e.g., userToken if auth */ });                                                                                                                              
                                                                                                                                                                                                                 
        socket.onOpen(() => connectionStatus.set('connected'));                                                                                                                                                  
        socket.onError(() => connectionStatus.set('error'));                                                                                                                                                     
        socket.onClose(() => connectionStatus.set('disconnected'));                                                                                                                                              
                                                                                                                                                                                                                 
        socket.connect();                                                                                                                                                                                        
                                                                                                                                                                                                                 
        channel = socket.channel('stocks:lobby', {});                                                                                                                                                            
        channel.join()                                                                                                                                                                                           
          .receive('ok', resp => {                                                                                                                                                                               
            console.log('Joined successfully', resp);                                                                                                                                                            
            // Initial data might be pushed by server after join                                                                                                                                                 
          })                                                                                                                                                                                                     
          .receive('error', resp => {                                                                                                                                                                            
            console.error('Unable to join', resp);                                                                                                                                                               
            connectionStatus.set('error');                                                                                                                                                                       
          });                                                                                                                                                                                                    
                                                                                                                                                                                                                 
        channel.on('initial_stocks', payload => {                                                                                                                                                                
          const initialStockData = {};                                                                                                                                                                           
          payload.stocks.forEach(stock => {                                                                                                                                                                      
            initialStockData[stock.symbol] = { ...stock, history: [stock.price] }; // Add price to history                                                                                                       
          });                                                                                                                                                                                                    
          stocks.set(initialStockData);                                                                                                                                                                          
        });                                                                                                                                                                                                      
                                                                                                                                                                                                                 
        channel.on('stock_update', payload => {                                                                                                                                                                  
          stocks.update(currentStocks => {                                                                                                                                                                       
            const symbol = payload.symbol;                                                                                                                                                                       
            const existingStock = currentStocks[symbol] || { history: [] };                                                                                                                                      
            const newHistory = [...existingStock.history, payload.price].slice(-50); // Keep last 50 points for chart                                                                                            
                                                                                                                                                                                                                 
            return {                                                                                                                                                                                             
              ...currentStocks,                                                                                                                                                                                  
              [symbol]: {                                                                                                                                                                                        
                ...existingStock,                                                                                                                                                                                
                ...payload,                                                                                                                                                                                      
                history: newHistory,                                                                                                                                                                             
              }                                                                                                                                                                                                  
            };                                                                                                                                                                                                   
          });                                                                                                                                                                                                    
          // Update portfolio summary (can be a derived store or calculated here)                                                                                                                                
        });                                                                                                                                                                                                      
      }                                                                                                                                                                                                          
                                                                                                                                                                                                                 
      export function disconnectSocket() {                                                                                                                                                                       
        if (channel) channel.leave();                                                                                                                                                                            
        if (socket) socket.disconnect();                                                                                                                                                                         
        socket = null;                                                                                                                                                                                           
        channel = null;                                                                                                                                                                                          
        connectionStatus.set('disconnected');                                                                                                                                                                    
      }                                                                                                                                                                                                          
                                                                                                                                                                                                                 
    • Call connectToSocket() in App.svelte's onMount.                                                                                                                                                            
 • Reactive UI Components:                                                                                                                                                                                       
    • Use Svelte's reactive declarations ($:) and store subscriptions ($stocks) to update UI automatically when data changes.                                                                                    
    • Example in StockCard.svelte:                                                                                                                                                                               
                                                                                                                                                                                                                 
      <script>                                                                                                                                                                                                   
        import { stocks } from '../stores/stockStore.js';                                                                                                                                                        
        export let symbol;                                                                                                                                                                                       
                                                                                                                                                                                                                 
        let stockData = null;                                                                                                                                                                                    
        $: stockData = $stocks[symbol] || { price: 'N/A', daily_change_percent: 'N/A', movement: 'neutral' };                                                                                                    
                                                                                                                                                                                                                 
        // $: movementClass = stockData.price > (stockData.previous_close || 0) ? 'up' : (stockData.price < (stockData.previous_close || 0) ? 'down' : 'neutral');                                               
        // A better way for movement is if backend sends it or calculates based on last price vs current.                                                                                                        
        // For now, let's assume backend sends a 'movement' indicator or we derive from price change.                                                                                                            
        $: priceMovement = parseFloat(stockData.daily_change_percent) > 0 ? 'up' : (parseFloat(stockData.daily_change_percent) < 0 ? 'down' : 'neutral');                                                        
      </script>                                                                                                                                                                                                  
                                                                                                                                                                                                                 
      <div class="stock-card" class:up={priceMovement === 'up'} class:down={priceMovement === 'down'}>                                                                                                           
        <h3>{symbol}</h3>                                                                                                                                                                                        
        <p>Price: {stockData.price}</p>                                                                                                                                                                          
        <p>Change: {stockData.daily_change_percent}%</p>                                                                                                                                                         
        <!-- Chart component here, passing stockData.history -->                                                                                                                                                 
      </div>                                                                                                                                                                                                     
                                                                                                                                                                                                                 
 • Chart Implementation:                                                                                                                                                                                         
    • Recommendation: Chart.js (with svelte-chartjs) or a lightweight Svelte-specific charting library like LayerCake or Pancake. For a "simple line chart", Chart.js is well-documented and capable.            
    • Wrap the chart library in a StockChart.svelte component.                                                                                                                                                   
    • Pass price history (e.g., stockData.history from the store) as a prop.                                                                                                                                     
    • Update the chart reactively when history changes.                                                                                                                                                          
 • Performance Optimization:                                                                                                                                                                                     
    • Debounce/Throttle: Not strictly necessary for Phoenix Channel updates if they are already optimized, but consider if UI updates become expensive.                                                          
    • Keyed Each Blocks: Use {#each items as item (item.id)} in Svelte for efficient list rendering.                                                                                                             
    • Minimize Data over WebSocket: Send only necessary data.                                                                                                                                                    
    • Backend Efficiency: Ensure ETS lookups and broadcasts are efficient.                                                                                                                                       

4. Integration Points                                                                                                                                                                                            

 • Data Structures (Backend <-> Frontend):                                                                                                                                                                       
    • From Backend to Frontend (via Phoenix Channel stock_update event):                                                                                                                                         
                                                                                                                                                                                                                 
      // Example for a single stock update                                                                                                                                                                       
      {                                                                                                                                                                                                          
        "symbol": "AAPL",                                                                                                                                                                                        
        "price": 150.25,                                                                                                                                                                                         
        "timestamp": 1678886400000, // Unix millis                                                                                                                                                               
        "daily_change_percent": 0.75, // Calculated by backend                                                                                                                                                   
        "previous_close": 149.13 // Needed for daily change calculation                                                                                                                                          
        // Potentially: "volume", "day_high", "day_low" if available and desired                                                                                                                                 
      }                                                                                                                                                                                                          
                                                                                                                                                                                                                 
    • Initial data (initial_stocks event): An array of the above structure.                                                                                                                                      
    • Frontend Store Structure (example):                                                                                                                                                                        
                                                                                                                                                                                                                 
      // $stocks store content                                                                                                                                                                                   
      {                                                                                                                                                                                                          
        "AAPL": {                                                                                                                                                                                                
          "symbol": "AAPL", "price": 150.25, "timestamp": ..., "daily_change_percent": 0.75, "previous_close": 149.13,                                                                                           
          "history": [150.00, 150.10, 150.25] // Array of recent prices for chart                                                                                                                                
        },                                                                                                                                                                                                       
        // ... other stocks                                                                                                                                                                                      
      }                                                                                                                                                                                                          
                                                                                                                                                                                                                 
 • Message Format Specifications: JSON over Phoenix Channels.                                                                                                                                                    
 • Authentication Flow:                                                                                                                                                                                          
    • Finnhub API: API key sent by FinnhubClient (backend) in WebSocket URL. Store this securely in Elixir config (e.g., config/runtime.exs or environment variables). DO NOT COMMIT API KEYS TO GIT.            
    • User Authentication (Frontend to Backend): Not specified as a core requirement. If added, Phoenix tokens (e.g., JWTs) would be used in UserSocket.connect/3. For this assignment, assume an open dashboard.
 • Error Handling (between systems):                                                                                                                                                                             
    • Frontend phoenixSocket.js handles WebSocket connection errors (onError, onClose) and updates connectionStatus store. UI components react to this store to show error/loading states.                       
    • Backend FinnhubClient handles Finnhub connection errors and attempts reconnection. If it fails persistently, it could broadcast a system status message.                                                   

5. Milestone Breakdown & Actionable Tasks                                                                                                                                                                        

Required Stocks: AAPL, MSFT, NVDA, GOOGL, JPM, BAC, V, AMZN, WMT, MCD.                                                                                                                                           

Milestone 1: Project Setup (Est. Time: 4-6 hours)                                                                                                                                                                

 • [ ] Task 1.1: Initialize Monorepo Structure.                                                                                                                                                                  
    • Create root directory, backend/, frontend/.                                                                                                                                                                
    • Setup .gitignore.                                                                                                                                                                                          
 • [ ] Task 1.2: Set up Phoenix Backend.                                                                                                                                                                         
    • cd backend && mix phx.new dashboard --app dashboard --no-ecto --no-html --no-assets (adjust if umbrella, but standalone is simpler here).                                                                  
    • Verify Phoenix server runs.                                                                                                                                                                                
 • [ ] Task 1.3: Create Svelte Frontend.                                                                                                                                                                         
    • cd frontend && npm create svelte@latest . (or pnpm create svelte@latest . / yarn create svelte .)                                                                                                          
    • Choose Skeleton project, select desired options (e.g., no TypeScript initially for simplicity unless comfortable, ESLint, Prettier).                                                                       
    • Verify Svelte dev server runs.                                                                                                                                                                             
 • [ ] Task 1.4: Establish Basic Connectivity (Phoenix Channel).                                                                                                                                                 
    • Implement a basic UserSocket and StockChannel in Phoenix.                                                                                                                                                  
    • Implement basic Svelte service to connect to the Phoenix Channel.                                                                                                                                          
    • Test: Frontend successfully connects to backend channel, logs a message.                                                                                                                                   
    • Test: Simple "ping/pong" message between frontend and backend via channel.                                                                                                                                 

Milestone 2: API Integration (Est. Time: 6-8 hours)                                                                                                                                                              

 • [ ] Task 2.1: Implement Finnhub API Authentication.                                                                                                                                                           
    • Securely configure Finnhub API key in Phoenix backend (e.g., config/dev.secret.exs, runtime.exs).                                                                                                          
 • [ ] Task 2.2: Create FinnhubClient GenServer.                                                                                                                                                                 
    • Basic GenServer structure.                                                                                                                                                                                 
    • Implement init/1 to attempt WebSocket connection to Finnhub using a WebSocket client library (e.g., websockex or gun).                                                                                     
    • Add FinnhubClient to the supervision tree (Dashboard.Application).                                                                                                                                         
    • Test: GenServer starts, logs successful connection to Finnhub (or connection attempt).                                                                                                                     
 • [ ] Task 2.3: Implement Basic Data Retrieval (Single Stock - AAPL).                                                                                                                                           
    • In FinnhubClient, subscribe to AAPL trade updates upon successful connection.                                                                                                                              
    • Handle incoming WebSocket messages from Finnhub, parse JSON.                                                                                                                                               
    • Log received AAPL price data.                                                                                                                                                                              
    • Test: Backend logs live price updates for AAPL from Finnhub.                                                                                                                                               
 • [ ] Task 2.4: Implement ETS Storage for Stock Data.                                                                                                                                                           
    • Create Dashboard.StockData.Cache module with init, put, get functions.                                                                                                                                     
    • Initialize ETS table.                                                                                                                                                                                      
    • Modify FinnhubClient to store received AAPL data into ETS.                                                                                                                                                 
    • Test: Use iex to query ETS table and verify AAPL data is present and updated.                                                                                                                              
 • [ ] Task 2.5: Implement Error Handling & Reconnection for FinnhubClient.                                                                                                                                      
    • Add logic to FinnhubClient to detect WebSocket disconnects/errors.                                                                                                                                         
    • Implement retry mechanism with exponential backoff.                                                                                                                                                        
    • Test: Manually simulate network interruption or stop Finnhub (if possible) / send invalid token to test reconnection.                                                                                      

Milestone 3: Data Flow (Est. Time: 5-7 hours)                                                                                                                                                                    

 • [ ] Task 3.1: Set up Phoenix Channels for Data Broadcasting.                                                                                                                                                  
    • Modify StockChannel to handle joining clients.                                                                                                                                                             
    • Modify FinnhubClient to broadcast AAPL stock updates via DashboardWeb.Endpoint.broadcast("stocks:lobby", "stock_update", data).                                                                            
 • [ ] Task 3.2: Create Data Transformation Utilities (if needed).                                                                                                                                               
    • Define the data structure for stock_update payload (see Integration Points).                                                                                                                               
    • Ensure FinnhubClient formats data correctly before broadcasting.                                                                                                                                           
    • Function in StockChannel or a helper module: format_stock_update(symbol, ets_data) to prepare data for frontend.                                                                                           
 • [ ] Task 3.3: Basic Frontend Component for Single Stock (AAPL).                                                                                                                                               
    • Create StockCard.svelte (very basic: display symbol and price).                                                                                                                                            
    • Modify phoenixSocket.js in Svelte to listen for stock_update events for AAPL.                                                                                                                              
    • Update stockStore.js with AAPL data.                                                                                                                                                                       
    • StockCard.svelte subscribes to the store and displays AAPL price.                                                                                                                                          
    • Test: AAPL price updates in real-time on the Svelte frontend.                                                                                                                                              
 • [ ] Task 3.4: Expand to All Required Stocks.                                                                                                                                                                  
    • Update FinnhubClient to subscribe to all 10 required stocks.                                                                                                                                               
    • Ensure ETS and broadcasting handle all stocks.                                                                                                                                                             
    • Frontend stockStore should handle multiple stocks.                                                                                                                                                         
    • Test: All 10 stocks show basic data on frontend (can be a simple list for now).                                                                                                                            

Milestone 4: Frontend Development (Est. Time: 8-10 hours)                                                                                                                                                        

 • [ ] Task 4.1: Build Dashboard UI Components.                                                                                                                                                                  
    • Create Dashboard.svelte to layout multiple StockCard components.                                                                                                                                           
    • Style StockCard.svelte to display symbol, price, daily percentage change.                                                                                                                                  
    • Implement visual indicators for price movements (up/down arrows, color changes based on daily_change_percent).                                                                                             
 • [ ] Task 4.2: Implement Real-time Data Display for All Stocks.                                                                                                                                                
    • Dynamically render StockCard components for each stock in the stockStore.                                                                                                                                  
    • Ensure all data points (price, change) update reactively.                                                                                                                                                  
 • [ ] Task 4.3: Create Stock Charts.                                                                                                                                                                            
    • Choose a charting library (e.g., Chart.js via svelte-chartjs).                                                                                                                                             
    • Integrate into StockCard.svelte or a new StockChart.svelte.                                                                                                                                                
    • Store a short history of prices for each stock in stockStore.                                                                                                                                              
    • Display a simple line chart of recent price movements for each stock.                                                                                                                                      
    • Test: Charts update with new price data.                                                                                                                                                                   
 • [ ] Task 4.4: Implement Portfolio Summary View.                                                                                                                                                               
    • Create PortfolioSummary.svelte.                                                                                                                                                                            
    • Calculate and display:                                                                                                                                                                                     
       • Total portfolio value (optional, as individual stock values are not the focus, but could be sum of current prices if 1 share each).                                                                     
       • Overall portfolio percentage change (e.g., average change, or market-cap weighted if data available - stick to simple average for now).                                                                 
    • This might require a derived store or calculations in phoenixSocket.js when stocks store updates.                                                                                                          
 • [ ] Task 4.5: Implement Loading States and Basic Error Display.                                                                                                                                               
    • Use connectionStatus store to show "Connecting...", "Connection Error", etc.                                                                                                                               
    • Show loading state for stock data before first data arrives.                                                                                                                                               

Milestone 5: Testing and Refinement (Est. Time: 7-9 hours)                                                                                                                                                       

 • [ ] Task 5.1: Add Backend Tests (Elixir).                                                                                                                                                                     
    • Unit tests for Dashboard.StockData.Cache functions.                                                                                                                                                        
    • Basic GenServer tests for FinnhubClient (e.g., init, handling mock messages if possible, though full WebSocket testing is integration).                                                                    
    • Channel tests for StockChannel (joining, broadcasting behavior with mock broadcasts).                                                                                                                      
    • Use ExUnit.                                                                                                                                                                                                
 • [ ] Task 5.2: Add Frontend Tests (Svelte).                                                                                                                                                                    
    • Component tests for StockCard.svelte, PortfolioSummary.svelte (using Vitest/Jest and Svelte Testing Library).                                                                                              
    • Test prop rendering, event handling (if any), store interactions.                                                                                                                                          
    • Test: Basic rendering, data display based on mock store data.                                                                                                                                              
 • [ ] Task 5.3: Implement Comprehensive Error Handling and Recovery.                                                                                                                                            
    • Backend: Robustness of FinnhubClient reconnection. What happens if API key is invalid? Log and don't crash.                                                                                                
    • Frontend: Graceful degradation if WebSocket disconnects. Clear error messages. Reconnection attempts by Phoenix.js client.                                                                                 
 • [ ] Task 5.4: Optimize Performance and Responsiveness.                                                                                                                                                        
    • Review data flow for bottlenecks.                                                                                                                                                                          
    • Ensure Svelte components update efficiently.                                                                                                                                                               
    • Test with simulated slower network conditions (browser dev tools).                                                                                                                                         
    • Ensure dashboard is responsive on different screen sizes (CSS).                                                                                                                                            

Milestone 6: Documentation and Submission (Est. Time: 5-7 hours)                                                                                                                                                 

 • [ ] Task 6.1: Complete Project Documentation.                                                                                                                                                                 
    • In-code comments for complex logic.                                                                                                                                                                        
    • Review and finalize README.md (project description, setup, architecture, screenshots).                                                                                                                     
 • [ ] Task 6.2: Create Milestone.md Report.                                                                                                                                                                     
    • Describe accomplishment of each milestone.                                                                                                                                                                 
    • Document challenges, solutions, AI utilization, lessons learned for each.                                                                                                                                  
 • [ ] Task 6.3: Final Code Review and Cleanup.                                                                                                                                                                  
    • Check for code quality, consistency, best practices.                                                                                                                                                       
    • Remove any debug code, console logs (except intentional ones).                                                                                                                                             
 • [ ] Task 6.4: Prepare GitHub Repository for Submission.                                                                                                                                                       
    • Ensure all .aider files and interaction history are committed.                                                                                                                                             
    • Verify all tests pass.                                                                                                                                                                                     
    • Final check of submission requirements from PDF.                                                                                                                                                           

6. Libraries and Versions                                                                                                                                                                                        

 • Elixir/Phoenix:                                                                                                                                                                                               
    • Elixir: ~> 1.15                                                                                                                                                                                            
    • Phoenix: ~> 1.7                                                                                                                                                                                            
    • websockex: ~> 0.4 (or gun if preferred for WebSocket client)                                                                                                                                               
    • jason: ~> 1.2 (for JSON parsing)                                                                                                                                                                           
 • Svelte/JavaScript:                                                                                                                                                                                            
    • Svelte: Latest version (~4.x or ~5.x if stable and comfortable)                                                                                                                                            
    • Vite: Latest version (as Svelte project builder)                                                                                                                                                           
    • phoenix: ~> 1.7 (npm package for Phoenix Channels client)                                                                                                                                                  
    • chart.js: ~> 4.x                                                                                                                                                                                           
    • svelte-chartjs: ~> 2.x (if using Chart.js)                                                                                                                                                                 
    • Testing: vitest, @testing-library/svelte                                                                                                                                                                   

7. Testing Strategy                                                                                                                                                                                              

 • Backend (Elixir - ExUnit):                                                                                                                                                                                    
    • Unit tests for pure functions (data transformation, cache logic).                                                                                                                                          
    • GenServer tests: Test init, handle_call, handle_cast, handle_info where possible. Mock external dependencies if complex.                                                                                   
    • Channel tests: Test join, message broadcasting/receiving logic.                                                                                                                                            
    • Focus on testing the logic within each module/process.                                                                                                                                                     
 • Frontend (Svelte - Vitest/Jest + Svelte Testing Library):                                                                                                                                                     
    • Component tests: Render components with various props and store states, verify output, test user interactions if any.                                                                                      
    • Store tests: Test logic within custom stores if complex (though Svelte's built-in stores are simple).                                                                                                      
    • Service tests: Mock Phoenix socket interactions to test data handling in phoenixSocket.js.                                                                                                                 
 • Integration Testing (Manual/End-to-End):                                                                                                                                                                      
    • Verify the entire flow: Finnhub -> Backend WebSocket -> ETS -> Phoenix Channel -> Svelte Frontend -> UI Update.                                                                                            
    • Test with real Finnhub connection.                                                                                                                                                                         
    • Test reconnection scenarios.                                                                                                                                                                               

8. Time Estimates                                                                                                                                                                                                

Provided per milestone. Total estimated core development time: ~35-47 hours. This is intensive for a weekend project; buffer time is crucial. AI assistance should help accelerate.                              

9. Technical Challenges and Solutions                                                                                                                                                                            

 • Challenge: Managing WebSocket lifecycle (Finnhub).                                                                                                                                                            
    • Solution: Robust GenServer with supervised restarts, exponential backoff for reconnections. Clear logging.                                                                                                 
 • Challenge: Real-time UI updates without performance degradation.                                                                                                                                              
    • Solution: Efficient Svelte reactivity, minimal data over channels, backend optimization (ETS).                                                                                                             
 • Challenge: Finnhub API rate limits or message structure nuances.                                                                                                                                              
    • Solution: Carefully read Finnhub docs. Handle unexpected messages gracefully. Log unknown message types.                                                                                                   
 • Challenge: Calculating daily percentage change accurately.                                                                                                                                                    
    • Solution: Requires previous day's closing price. Finnhub might provide this, or it might need to be fetched via a separate HTTP request once per day per stock, or inferred if not directly in WebSocket   
      feed. For simplicity, if the WebSocket feed provides a daily change or previous close, use that. Otherwise, the FinnhubClient might need to fetch this at startup or periodically. The current plan assumes
      the WebSocket feed or a simple calculation based on first price of day vs current is sufficient. If not, this task needs to be added. Initial approach: Assume Finnhub's trade data includes enough info or
      calculate change based on the first price received after connection for that day.                                                                                                                          

10. Debugging Strategies                                                                                                                                                                                         

 • Elixir/Phoenix:                                                                                                                                                                                               
    • IO.inspect() for quick checks.                                                                                                                                                                             
    • Logger for more persistent logging.                                                                                                                                                                        
    • iex -S mix phx.server for interactive debugging, querying ETS, tracing messages.                                                                                                                           
    • Observer: :observer.start() for visualizing processes and message queues.                                                                                                                                  
    • Dialyzer for static analysis.                                                                                                                                                                              
 • Svelte:                                                                                                                                                                                                       
    • Browser DevTools (Console, Network tab for WebSocket frames, Svelte Devtools extension).                                                                                                                   
    • console.log() in Svelte components/stores.                                                                                                                                                                 
    • Svelte Devtools for inspecting component state and hierarchy.                                                                                                                                              
 • WebSockets:                                                                                                                                                                                                   
    • Browser Network tab to inspect Phoenix Channel messages.                                                                                                                                                   
    • Logging on both client and server for message flow.                                                                                                                                                        
    • Wireshark or similar for deep packet inspection if necessary (rarely needed).                                                                                                                              

11. Performance Considerations                                                                                                                                                                                   

 • Backend:                                                                                                                                                                                                      
    • Use :public and read_concurrency: true for ETS table for efficient reads from many channel processes.                                                                                                      
    • Minimize work done in FinnhubClient's message handling loop. Offload heavy processing if any.                                                                                                              
    • Batch broadcasts if many updates arrive simultaneously for different stocks (though Finnhub is real-time per trade, so likely not an issue).                                                               
 • Frontend:                                                                                                                                                                                                     
    • Use keyed {#each} blocks in Svelte.                                                                                                                                                                        
    • Memoize expensive computations if any in Svelte components.                                                                                                                                                
    • Limit frequency of chart redraws if they become a bottleneck (e.g., by only updating chart every Nth price update or every X ms).                                                                          
    • Virtual lists if displaying a huge number of stocks (not the case here).                                                                                                                                   

12. Refactoring Points                                                                                                                                                                                           

 • After Milestone 3 (Data Flow for 1 stock): Review FinnhubClient and StockChannel logic before scaling to all stocks.                                                                                          
 • After Milestone 4 (Frontend Dev): Review Svelte component structure and store logic. Are there too many props being passed? Can stores be simplified?                                                         
 • Error Handling: Consolidate error handling patterns.                                                                                                                                                          
 • Configuration: Ensure all configurable values (API keys, URLs) are externalized.                                                                                                                              

13. Development Approach (Refined)                                                                                                                                                                               

The PDF's suggested approach is good. Refinements:                                                                                                                                                               

 1 Monorepo & Basic Setup First (Milestone 1): Establish the complete project structure and basic "hello world" connectivity between Phoenix and Svelte before any API integration.                              
 2 Single Stock End-to-End with Core Logic (Milestones 2 & 3 for AAPL): Implement the full data flow for AAPL, including:                                                                                        
    • Finnhub connection and data parsing.                                                                                                                                                                       
    • ETS storage.                                                                                                                                                                                               
    • Phoenix Channel broadcast.                                                                                                                                                                                 
    • Svelte store update and basic UI display.                                                                                                                                                                  
    • Crucially: Implement basic error handling (Finnhub connection, WebSocket messages) and reconnection logic for this single stock flow early.                                                                
 3 Incremental Testing: Write tests for each component/module as it's developed, not just in Milestone 5. E.g., test ETS cache functions when Cache.ex is created.                                               
 4 Expand to Multiple Stocks: Once the single-stock pipeline is robust, then expand FinnhubClient subscriptions and frontend rendering for all required stocks.                                                  
 5 Layer Features Incrementally (Milestone 4):                                                                                                                                                                   
    • Basic price/change display.                                                                                                                                                                                
    • Visual indicators.                                                                                                                                                                                         
    • Charts.                                                                                                                                                                                                    
    • Portfolio summary.                                                                                                                                                                                         
 6 Continuous Refinement & Testing (Milestone 5 integrated throughout): Don't leave all testing and refinement to the end. Perform mini-cycles of development, testing, and refinement.                          
 7 Continuous Documentation: Document code, architecture, and decisions as you go. README.md and Milestone.md should be living documents.                                                                        
 8 UI Enhancements and Advanced Optimizations: Address these after core functionality is stable and tested.                                                                                                      

This refined approach emphasizes building a solid, tested foundation early and iterating with continuous integration of testing and documentation.                                                               

14. Learning Opportunities                                                                                                                                                                                       

 • Elixir Concurrency: Deep dive into GenServer behaviors, supervision strategies, and the actor model.                                                                                                          
 • Phoenix Channels: Understand bi-directional communication, topics, broadcasting, and presence (though presence not used here).                                                                                
 • ETS: Learn about in-memory storage, table types, access controls, and performance trade-offs.                                                                                                                 
 • Svelte Reactivity: Master Svelte stores, reactive statements ($:), and component lifecycle for efficient UI updates.                                                                                          
 • API Integration: Best practices for consuming third-party WebSocket APIs, error handling, and data parsing.                                                                                                   
 • Monorepo Workflows: Managing separate but related projects in one repository.                                                                                                                                 

15. Documentation and Submission Guidance                                                                                                                                                                        

 • GitHub Repository:                                                                                                                                                                                            
    • Initialize Git in the financial_dashboard_monorepo root.                                                                                                                                                   
    • Commit .aider files and interaction history regularly.                                                                                                                                                     
    • Ensure backend/ and frontend/ have their own comprehensive tests.                                                                                                                                          
 • README.md (root level):                                                                                                                                                                                       
    • Project Description: What the project is, its purpose.                                                                                                                                                     
    • Setup Instructions: How to clone, install dependencies for backend and frontend, configure API key (mentioning .env or dev.secret.exs for backend, and NOT to commit the key), and run both applications.  
    • Architecture Explanation: Overview of backend (Phoenix, GenServer, ETS, Channels) and frontend (Svelte, components, stores, WebSocket service). Include a simple diagram if possible (text-based or linked 
      image).                                                                                                                                                                                                    
    • Screenshots: Of the working application.                                                                                                                                                                   
 • Milestone.md (root level):                                                                                                                                                                                    
    • For each of the 6 milestones:                                                                                                                                                                              
       • A paragraph describing what was accomplished.                                                                                                                                                           
       • Challenges encountered and how they were resolved.                                                                                                                                                      
       • How Aider and opto-gpt were utilized (specific prompts, conceptual help).                                                                                                                               
       • Lessons learned during that phase.                                                                                                                                                                      
 • Code Comments: Add comments to Elixir and JavaScript code for complex logic or non-obvious decisions.