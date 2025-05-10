<script>
  import { onMount } from 'svelte';

  // Accept either array of numbers or array of objects with price property
  export let history = [];
  export let symbol = '';

  let chartElement;
  let chartData = [];
  let isRendered = false;
  
  // Calculate moving average period - 1/4 of data points or at least 5
  $: movingAveragePeriod = Math.max(5, Math.floor(chartData.length / 4));

  // Process the history data to extract prices regardless of format
  $: {
    if (history && history.length > 0) {
      // Check if history contains objects with price property or direct numbers
      if (typeof history[0] === 'object' && history[0] !== null) {
        // Extract price from objects (assuming each object has a price property)
        chartData = history.map(item => item.price || 0);
      } else {
        // Direct array of numbers
        chartData = [...history];
      }
    } else {
      chartData = [];
    }
  }

  // Calculate moving average for the data
  function calculateMovingAverage(data, period) {
    if (!data || data.length < period) return [];
    
    const result = [];
    for (let i = 0; i < data.length; i++) {
      if (i < period - 1) {
        // Not enough previous data points for full window
        result.push(null);
      } else {
        // Calculate average for the window
        const sum = data.slice(i - period + 1, i + 1).reduce((a, b) => a + b, 0);
        result.push(sum / period);
      }
    }
    return result;
  }
  
  // Apply Bezier curve interpolation for a smoother line
  function createSmoothPath(ctx, points) {
    if (points.length < 2) return;
    
    ctx.beginPath();
    ctx.moveTo(points[0].x, points[0].y);
    
    // Use quadratic curves for smoother lines
    for (let i = 0; i < points.length - 1; i++) {
      const xc = (points[i].x + points[i + 1].x) / 2;
      const yc = (points[i].y + points[i + 1].y) / 2;
      
      // Use quadratic bezier curves for smoother lines
      ctx.quadraticCurveTo(points[i].x, points[i].y, xc, yc);
    }
    
    // Connect to the last point
    ctx.quadraticCurveTo(
      points[points.length - 2].x, 
      points[points.length - 2].y, 
      points[points.length - 1].x, 
      points[points.length - 1].y
    );
  }
  
  // Draw a single price point visualization
  function drawSinglePricePoint(ctx, width, height, price) {
    if (!ctx) return;
    
    // Clear canvas
    ctx.clearRect(0, 0, width, height);
    
    // Draw a horizontal line across middle of canvas
    const y = height / 2;
    ctx.beginPath();
    ctx.strokeStyle = '#e0e0e0';
    ctx.lineWidth = 1;
    ctx.moveTo(0, y);
    ctx.lineTo(width, y);
    ctx.stroke();
    
    // Draw a point in the center
    ctx.beginPath();
    ctx.fillStyle = '#4CAF50';
    ctx.arc(width/2, y, 5, 0, Math.PI * 2);
    ctx.fill();
    
    // Draw price text
    ctx.font = '12px sans-serif';
    ctx.fillStyle = '#666';
    ctx.textAlign = 'center';
    ctx.fillText(`$${typeof price === 'number' ? price.toFixed(2) : price}`, width/2, y - 10);
  }

  onMount(() => {
    renderChart();
  });

  // Update chart when data changes - this is critical
  $: if (chartData && chartElement) {
    renderChart();
  }

  function renderChart() {
    if (!chartElement) return;

    const ctx = chartElement.getContext('2d');
    if (!ctx) return;
    
    const width = chartElement.width;
    const height = chartElement.height;
    
    // Clear canvas
    ctx.clearRect(0, 0, width, height);
    
    // Handle single data point case
    if (chartData && chartData.length === 1) {
      drawSinglePricePoint(ctx, width, height, chartData[0]);
      isRendered = true;
      return;
    }
    
    if (!chartData || chartData.length < 2) return;
    
    try {
      // Find min and max values for scaling
      const prices = [...chartData]; // Create a copy to avoid modifying the original
      const validPrices = prices.filter(price => typeof price === 'number' && !isNaN(price));
      
      if (validPrices.length < 2) return;
      
      // Calculate moving average
      const movingAvg = calculateMovingAverage(validPrices, movingAveragePeriod);
      
      const allValues = [...validPrices, ...movingAvg.filter(val => val !== null)];
      const minPrice = Math.min(...allValues);
      const maxPrice = Math.max(...allValues);
      
      // Add padding to the price range (15% on top and bottom)
      const pricePadding = (maxPrice - minPrice) * 0.15;
      const paddedMinPrice = minPrice - pricePadding;
      const paddedMaxPrice = maxPrice + pricePadding;
      const priceRange = paddedMaxPrice - paddedMinPrice || 1; // Avoid division by zero
      
      // Prepare points for the main line
      const mainPoints = validPrices.map((price, index) => {
        const x = (index / (validPrices.length - 1)) * width;
        const normalizedPrice = 1 - ((price - paddedMinPrice) / priceRange);
        const y = normalizedPrice * height;
        return { x, y };
      });
      
      // Prepare points for the moving average line
      const maPoints = movingAvg.map((price, index) => {
        if (price === null) return null;
        const x = (index / (validPrices.length - 1)) * width;
        const normalizedPrice = 1 - ((price - paddedMinPrice) / priceRange);
        const y = normalizedPrice * height;
        return { x, y };
      }).filter(point => point !== null);
      
      // Draw main price line - using standard color instead of changing based on trend
      ctx.strokeStyle = '#4CAF50'; // Standard green color for the main line
      ctx.lineWidth = 2;
      
      createSmoothPath(ctx, mainPoints);
      ctx.stroke();
      
      // Draw moving average line if we have enough data points
      if (maPoints.length > 1) {
        ctx.beginPath();
        ctx.setLineDash([5, 3]); // Dashed line
        ctx.strokeStyle = '#2196F3'; // Blue for moving average
        ctx.lineWidth = 1.5;
        
        ctx.moveTo(maPoints[0].x, maPoints[0].y);
        for (let i = 1; i < maPoints.length; i++) {
          ctx.lineTo(maPoints[i].x, maPoints[i].y);
        }
        
        ctx.stroke();
        ctx.setLineDash([]); // Reset to solid line
      }
      
      isRendered = true;
    } catch (error) {
      console.error(`Error rendering chart for ${symbol}:`, error);
    }
  }
</script>

<div class="chart-container">
  <h4>{symbol} Price History</h4>
  
  <canvas bind:this={chartElement} width="250" height="100"></canvas>
  
  {#if chartData.length > 1}
    <div class="legend">
      <div class="legend-item">
        <span class="legend-line main-line"></span>
        <span class="legend-text">Price</span>
      </div>
      {#if chartData.length >= movingAveragePeriod}
        <div class="legend-item">
          <span class="legend-line ma-line"></span>
          <span class="legend-text">{movingAveragePeriod}-point MA</span>
        </div>
      {/if}
    </div>
  {:else if chartData.length === 0}
    <div class="no-data">No historical data available</div>
  {/if}
</div>

<style>
  .chart-container {
    margin-top: 1em;
    width: 100%;
    height: 130px; /* Fixed height for consistent card sizing */
    display: flex;
    flex-direction: column;
  }
  
  h4 {
    font-size: 0.9em;
    margin: 0 0 5px 0;
    color: #555;
  }
  
  canvas {
    width: 100%;
    height: 100px;
    background-color: #f5f5f5;
    border-radius: 3px;
  }
  
  .no-data {
    text-align: center;
    color: #999;
    font-style: italic;
    font-size: 0.8em;
    margin-top: 30px;
    position: absolute;
    width: 100%;
  }
  
  .legend {
    display: flex;
    justify-content: center;
    gap: 15px;
    margin-top: 2px;
    font-size: 0.7em;
  }
  
  .legend-item {
    display: flex;
    align-items: center;
    gap: 5px;
  }
  
  .legend-line {
    display: inline-block;
    width: 15px;
    height: 2px;
  }
  
  .main-line {
    background-color: #4CAF50; /* Updated to match the standard green color */
  }
  
  .ma-line {
    background-color: #2196F3;
    height: 2px;
    border-top: 1px dashed #2196F3;
  }
  
  .legend-text {
    color: #666;
  }
</style>
