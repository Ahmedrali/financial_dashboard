<script>
  import { portfolioSummary } from '../stores/stockStore.js';

  $: summary = $portfolioSummary || { totalValue: 0, averageChangePercent: 0, stockCount: 0 };

  function formatCurrency(value) {
    return typeof value === 'number' ? value.toFixed(2) : 'N/A';
  }

  function formatPercentage(value) {
    return typeof value === 'number' ? value.toFixed(2) + '%' : 'N/A';
  }
</script>

<div class="portfolio-summary">
  <h2>Portfolio Overview</h2>
  {#if summary.stockCount > 0}
    <div class="summary-item">
      <span class="label">Total Portfolio Value (Est.):</span>
      <span class="value">${formatCurrency(summary.totalValue)}</span>
    </div>
    <div class="summary-item">
      <span class="label">Average Daily Change:</span>
      <span class="value {summary.averageChangePercent > 0 ? 'up' : summary.averageChangePercent < 0 ? 'down' : 'neutral'}">
        {formatPercentage(summary.averageChangePercent)}
      </span>
    </div>
    <div class="summary-item">
      <span class="label">Number of Stocks Tracked:</span>
      <span class="value">{summary.stockCount}</span>
    </div>
  {:else}
    <p>Calculating portfolio summary...</p>
  {/if}
</div>

<style>
  .portfolio-summary {
    padding: 1em;
    border: 1px solid #e0e0e0;
    border-radius: 8px;
    background-color: #f9f9f9;
    margin-bottom: 1.5em;
  }
  .portfolio-summary h2 {
    margin-top: 0;
    color: #333;
    font-size: 1.5em;
    border-bottom: 1px solid #eee;
    padding-bottom: 0.5em;
    margin-bottom: 0.75em;
  }
  .summary-item {
    display: flex;
    justify-content: space-between;
    padding: 0.5em 0;
    font-size: 1.1em;
  }
  .summary-item .label {
    color: #555;
    font-weight: 500;
  }
  .summary-item .value {
    font-weight: bold;
    color: #333;
  }
  .value.up {
    color: #4CAF50; /* Green */
  }
  .value.down {
    color: #F44336; /* Red */
  }
  .value.neutral {
    color: #333; /* Dark Grey for neutral text */
  }
  p {
    color: #666;
  }
</style>
