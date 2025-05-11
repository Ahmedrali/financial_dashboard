<script>
  import { onMount, onDestroy } from 'svelte';
  import { connectToSocket, disconnectSocket, pingServer } from '$lib/phoenixSocket.js';
  // Import stores
  import { connectionStatus, lastPong, stocks, portfolioSummary } from '../stores/stockStore.js';
  import StockCard from '../components/StockCard.svelte';
  import PortfolioSummary from '../components/PortfolioSummary.svelte'; // Import the new summary component

  onMount(() => {
    connectToSocket();
  });

  onDestroy(() => {
    disconnectSocket();
  });

  function handlePing() {
    pingServer({ data: "Hello from Svelte on " + new Date().toLocaleTimeString() });
  }

  // Reactive declaration for all stocks, sorted by symbol for consistent order
  $: stockList = Object.values($stocks).sort((a, b) => a.symbol.localeCompare(b.symbol));

</script>

<main>
  <h1>Real-Time Financial Dashboard</h1>
  
  <section class="connection-status">
    <h2>WebSocket Connection</h2>
    {#if $connectionStatus === 'connecting'}
      <p>Status: Connecting to server...</p>
    {:else if $connectionStatus === 'connected'}
      <p>Status: Connected</p>
      <button on:click={handlePing}>Send Ping</button>
    {:else if $connectionStatus === 'error'}
      <p>Status: Connection error. Please try reconnecting.</p>
      <button on:click={connectToSocket}>Reconnect</button>
    {:else if $connectionStatus === 'closed'}
      <p>Status: Connection closed. Please try reconnecting.</p>
      <button on:click={connectToSocket}>Reconnect</button>
    {:else if $connectionStatus === 'disconnected'}
      <p>Status: Disconnected. Please try reconnecting.</p>
      <button on:click={connectToSocket}>Reconnect</button>
    {/if}
  </section>

  <PortfolioSummary />

  {#if $lastPong}
    <section class="debug-info">
      <h2>Last Pong Received:</h2>
      <pre>{JSON.stringify($lastPong, null, 2)}</pre>
    </section>
  {/if}

  <section class="dashboard-grid">
    <h2>Stock Data</h2>
    <div class="stock-cards-container">
      <!-- Display stock cards for all stocks -->
      {#if stockList.length > 0}
        {#each stockList as stock (stock.symbol)}
          <StockCard {stock} />
        {/each}
      {:else}
        {#if $connectionStatus === 'connecting'}
          <p>Connecting to server to fetch stock data...</p>
        {:else if $connectionStatus === 'connected'}
          <p>No stock data received yet. Waiting for updates...</p>
        {:else if $connectionStatus === 'error'}
          <p>Error fetching stock data. Please check the connection and try reconnecting.</p>
        {:else if $connectionStatus === 'closed'}
          <p>Connection closed. Unable to fetch stock data. Please try reconnecting.</p>
        {:else if $connectionStatus === 'disconnected'}
          <p>Disconnected. Please connect to see stock data.</p>
        {:else}
          <p>Not connected. Please check connection status.</p> <!-- Fallback for any unhandled status -->
        {/if}
      {/if}
    </div>
  </section>

  <footer>
    <p>Visit <a href="https://svelte.dev/docs/kit">svelte.dev/docs/kit</a> to read the SvelteKit documentation.</p>
  </footer>
</main>

<style>
  main {
    font-family: sans-serif;
    padding: 1em;
    max-width: 1200px;
    margin: 0 auto;
  }
  section {
    margin-bottom: 1.5em;
    padding: 1em;
    border: 1px solid #eee;
    border-radius: 4px;
    background-color: #fff;
  }
  .connection-status, .debug-info {
    background-color: #f9f9f9;
  }
  .dashboard-grid h2 {
    margin-top: 0;
  }
  .stock-cards-container {
    display: grid; 
    grid-template-columns: repeat(3, 1fr); /* Exactly 3 cards per row */
    gap: 3.5em; /* Increased spacing between cards */
    padding: 0.5em; /* Added padding around the container */
    width: 90%; /* Reduce the overall width to make cards less wide */
    margin: 0 auto; /* Center the grid in the container */
  }
  pre {
    background-color: #f0f0f0;
    padding: 0.5em;
    border-radius: 4px;
    overflow-x: auto;
  }
</style>
