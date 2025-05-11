# Real-Time Financial Dashboard (Monorepo)

This project is a real-time financial dashboard built with Elixir/Phoenix for the backend and Svelte for the frontend. It connects to Finnhub's WebSocket API to display live stock market data for a predefined portfolio of 10 stocks (AAPL, MSFT, NVDA, GOOGL, JPM, BAC, V, AMZN, WMT, MCD).

## Project Structure

- `backend/`: Contains the Phoenix application with WebSocket connection handling, stock data caching, and channel broadcasting.
- `frontend/`: Contains the Svelte application with reactive components for displaying real-time stock data.

## Setup and Running

### Prerequisites

- Elixir 1.14+ and Erlang 25+
- Node.js 16+ and npm 8+
- Finnhub API key (register at [finnhub.io](https://finnhub.io/))

### Backend (Phoenix)

```bash
cd financial_dashboard_monorepo/backend/dashboard
# Install dependencies
mix deps.get
# Configure your Finnhub API key in config/dev.secret.exs
# Create config/dev.secret.exs with: 
# import Config
# config :dashboard, finnhub_api_key: "YOUR_API_KEY"
# Start the Phoenix server
mix phx.server
```

### Frontend (Svelte)

```bash
cd financial_dashboard_monorepo/frontend
# Install dependencies
npm install
# Start the development server
npm run dev
```

The frontend will be available at http://localhost:5173 and will automatically connect to the Phoenix backend running at http://localhost:4000.

## Architecture

### Backend Architecture (Elixir/Phoenix)

The backend system is built with Elixir and Phoenix, leveraging the power of OTP (Open Telecom Platform) for concurrency and fault tolerance:

1. **Supervision Tree**: 
   - `Dashboard.Application` supervises all components
   - `Dashboard.StockData.Supervisor` manages stock data processes

2. **Key Components**:
   - `FinnhubWebSocketClient`: GenServer that connects to Finnhub's WebSocket API
   - `StockData.Cache`: ETS-based cache for storing real-time stock data
   - `StockChannel`: Phoenix Channel for broadcasting updates to frontend clients

3. **Data Flow**:
   - Finnhub WebSocket → FinnhubWebSocketClient → StockData.Cache → Phoenix PubSub → StockChannel → Frontend

### Frontend Architecture (Svelte)

The frontend uses Svelte for its reactive UI components and efficient updates:

1. **Key Components**:
   - `StockCard.svelte`: Displays data for a single stock (price, change, chart)
   - `PortfolioSummary.svelte`: Shows aggregated portfolio statistics
   - `StockChart.svelte`: Renders price history as line chart with moving averages

2. **State Management**:
   - `stockStore.js`: Central store managing stock data and WebSocket connection state
   - Svelte's reactive system automatically updates the UI when stock data changes

3. **WebSocket Communication**:
   - `phoenixSocket.js`: Handles connection to Phoenix Channels
   - Populates Svelte stores with real-time data received from the backend


## Features

- Real-time stock price updates via WebSocket
- Historical price charts with moving averages
- Portfolio summary statistics
- Color-coded price movements
- Responsive design
- Automatic reconnection handling

## Technologies Used

- **Backend**: Elixir, Phoenix, OTP (GenServer, Supervisors), ETS
- **Frontend**: Svelte, Chart.js
- **Communication**: WebSockets, Phoenix Channels
- **External API**: Finnhub Stock API
