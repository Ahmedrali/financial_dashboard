<script>
  import StockChart from './StockChart.svelte';

  export let stock = {
    symbol: 'N/A',
    price: 'N/A',
    daily_change_percent: 'N/A',
    previous_close: 'N/A',
    timestamp: null,
    history: []
  };

  $: priceMovement = parseFloat(stock.daily_change_percent) > 0 ? 'up' : (parseFloat(stock.daily_change_percent) < 0 ? 'down' : 'neutral');
  $: formattedPrice = typeof stock.price === 'number' ? stock.price.toFixed(2) : stock.price;
  $: formattedChange = typeof stock.daily_change_percent === 'number' ? stock.daily_change_percent.toFixed(2) + '%' : stock.daily_change_percent;
</script>

<div class="stock-card" class:up={priceMovement === 'up'} class:down={priceMovement === 'down'} class:neutral={priceMovement === 'neutral'}>
  <div class="header">
    <h3>{stock.symbol}</h3>
    <span class="movement-indicator {priceMovement}">
      {#if priceMovement === 'up'}▲
      {:else if priceMovement === 'down'}▼
      {:else}—
      {/if}
    </span>
  </div>
  <p class="price">${formattedPrice}</p>
  <p class="change {priceMovement}">Change: {formattedChange}</p>
  <p class="previous-close">Prev. Close: ${stock.previous_close ? stock.previous_close.toFixed(2) : 'N/A'}</p>
  <StockChart history={stock.history} symbol={stock.symbol} />
  <p class="timestamp">Last updated: {stock.timestamp ? new Date(stock.timestamp).toLocaleTimeString() : 'N/A'}</p>
</div>

<style>
  .stock-card {
    border: 1px solid #ccc;
    padding: 1em;
    margin: 0;
    border-radius: 4px;
    min-width: unset; /* Remove min-width restriction */
    max-width: unset; /* Remove max-width restriction */
    width: 100%; /* Allow card to fill the grid cell */
    background-color: #f9f9f9;
    transition: background-color 0.3s ease, border-color 0.3s ease;
    box-shadow: 0 2px 4px rgba(0,0,0,0.1);
    display: flex;
    flex-direction: column;
    height: 280px;
  }
  .header {
    display: flex;
    justify-content: space-between;
    align-items: center;
    margin-bottom: 0.5em;
  }
  .stock-card h3 {
    margin-top: 0;
    margin-bottom: 0; /* Adjusted for header layout */
    font-size: 1.5em;
    white-space: nowrap; /* Prevent symbol from wrapping */
    overflow: hidden; /* Hide overflow */
    text-overflow: ellipsis; /* Add ellipsis for overflowed text */
  }
  .movement-indicator {
    font-size: 1.5em;
    font-weight: bold;
  }
  .price {
    font-size: 1.4em; /* Made price slightly larger */
    font-weight: bold;
    margin: 0.3em 0;
  }
  .change {
    font-size: 1em;
    margin: 0.3em 0;
  }
  .previous-close {
    font-size: 0.9em;
    color: #333;
    margin: 0.3em 0;
  }
  .timestamp {
    font-size: 0.8em;
    color: #666;
    margin-top: 0.5em;
  }

  /* Color coding for price movement */
  .stock-card.up {
    border-left: 5px solid #4CAF50; /* Green */
  }
  .stock-card.down {
    border-left: 5px solid #F44336; /* Red */
  }
  .stock-card.neutral {
    border-left: 5px solid #9E9E9E; /* Grey */
  }

  .change.up {
    color: #4CAF50; /* Green */
  }
  .change.down {
    color: #F44336; /* Red */
  }
  .change.neutral {
    color: #333; /* Dark Grey for neutral text */
  }
  .movement-indicator.up { color: #4CAF50; }
  .movement-indicator.down { color: #F44336; }
  .movement-indicator.neutral { color: #333; }
</style>
