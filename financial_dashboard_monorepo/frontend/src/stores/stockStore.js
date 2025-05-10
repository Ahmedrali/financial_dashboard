import { writable, derived } from 'svelte/store';

/**
 * Stores the connection status of the WebSocket.
 * Values: 'disconnected', 'connecting', 'connected', 'error', 'closed'
 */
export const connectionStatus = writable('disconnected');

/**
 * Stores the actual stock data.
 * Structure: { SYMBOL: { price: number, timestamp: number, daily_change_percent: number, previous_close: number, history: number[] }, ... }
 */
export const stocks = writable({});

/**
 * Stores the last pong message received from the server, primarily for debugging.
 */
export const lastPong = writable(null);

/**
 * Derived store for portfolio summary calculations.
 * Assumes 1 share per stock for total value calculation.
 */
export const portfolioSummary = derived(
  stocks,
  ($stocks) => {
    const stockArray = Object.values($stocks);
    const stockCount = stockArray.length;

    if (stockCount === 0) {
      return { totalValue: 0, averageChangePercent: 0, stockCount: 0 };
    }

    const totalValue = stockArray.reduce((acc, stock) => {
      // Ensure price is a number and not NaN before adding
      const price = parseFloat(stock.price);
      return acc + (isNaN(price) ? 0 : price);
    }, 0);

    const sumOfChanges = stockArray.reduce((acc, stock) => {
      // Ensure daily_change_percent is a number and not NaN
      const change = parseFloat(stock.daily_change_percent);
      return acc + (isNaN(change) ? 0 : change);
    }, 0);
    
    const averageChangePercent = stockCount > 0 ? sumOfChanges / stockCount : 0;

    return {
      totalValue,
      averageChangePercent,
      stockCount
    };
  }
);
