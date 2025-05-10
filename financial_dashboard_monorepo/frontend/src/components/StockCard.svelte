<script>
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

<div class="stock-card" class:up={priceMovement === 'up'} class:down={priceMovement === 'down'}>
  <h3>{stock.symbol}</h3>
  <p class="price">Price: ${formattedPrice}</p>
  <!-- For Task 3.3, we'll keep it simple. More details in Task 4.1 -->
  <!-- <p class="change">Change: {formattedChange}</p> -->
  <!-- <p class="timestamp">Last updated: {stock.timestamp ? new Date(stock.timestamp).toLocaleTimeString() : 'N/A'}</p> -->
</div>

<style>
  .stock-card {
    border: 1px solid #ccc;
    padding: 1em;
    margin: 0.5em;
    border-radius: 4px;
    width: 200px;
    background-color: #f9f9f9;
    transition: background-color 0.3s ease;
  }
  .stock-card h3 {
    margin-top: 0;
    font-size: 1.5em;
  }
  .price {
    font-size: 1.2em;
    font-weight: bold;
  }
  .change {
    font-size: 1em;
  }
  .timestamp {
    font-size: 0.8em;
    color: #666;
  }
  .stock-card.up {
    /* background-color: #e6ffed; */
    border-left: 5px solid green;
  }
  .stock-card.down {
    /* background-color: #ffebee; */
    border-left: 5px solid red;
  }
</style>
