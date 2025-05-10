import { writable } from 'svelte/store';

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
