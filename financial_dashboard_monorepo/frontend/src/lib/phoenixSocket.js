// place files you want to import through the `$lib` alias in this folder.
import { Socket } from 'phoenix';
// Import stores from the dedicated store file
import { stocks, connectionStatus, lastPong } from '../stores/stockStore.js';

let socket;
let channel;

const PHOENIX_SOCKET_URL = 'ws://localhost:4000/socket';

export function connectToSocket() {
  if (socket) return;

  connectionStatus.set('connecting');
  console.log('Attempting to connect to Phoenix Socket...');

  socket = new Socket(PHOENIX_SOCKET_URL, {
    params: { user_token: 'dummy_token_for_now' } // Example params
  });

  socket.onOpen(() => {
    connectionStatus.set('connected');
    console.log('Phoenix Socket connected!');
    joinStockChannel();
  });

  socket.onError((error) => {
    connectionStatus.set('error');
    console.error('Phoenix Socket error:', error);
  });

  socket.onClose(() => {
    connectionStatus.set('closed');
    console.log('Phoenix Socket connection closed.');
    channel = null; // Clear channel on close
  });

  socket.connect();
}

function joinStockChannel() {
  if (!socket) {
    console.error('Socket not connected, cannot join channel.');
    return;
  }

  channel = socket.channel('stocks:lobby', {});

  channel.join()
    .receive('ok', resp => {
      console.log('Joined "stocks:lobby" channel successfully', resp);
    })
    .receive('error', resp => {
      console.error('Unable to join "stocks:lobby" channel', resp);
      connectionStatus.set('error');
    });

  // Listen for "pong" messages from the server
  channel.on('pong', payload => {
    console.log('Received pong:', payload);
    lastPong.set(payload);
  });

  // Listen for initial stock data
  channel.on('initial_stocks', payload => {
    console.log('Received initial_stocks:', payload);
    const initialStockData = {};
    if (payload.stocks && Array.isArray(payload.stocks)) {
      payload.stocks.forEach(stock => {
        initialStockData[stock.symbol] = {
          ...stock,
          // Initialize history with the current price or an empty array if no price
          history: stock.price ? [stock.price] : []
        };
      });
      stocks.set(initialStockData);
    } else {
      console.warn("Received 'initial_stocks' but payload.stocks was not an array or undefined:", payload);
      stocks.set({}); // Set to empty if data is malformed
    }
  });

  // Listen for real-time stock updates
  channel.on('stock_update', payload => {
    // console.log('Received stock_update:', payload); // Can be very verbose
    stocks.update(currentStocks => {
      const symbol = payload.symbol;
      if (!symbol) {
        console.warn("Received 'stock_update' without a symbol:", payload);
        return currentStocks;
      }
      const existingStock = currentStocks[symbol] || { history: [] };
      const newHistory = [...existingStock.history, payload.price].slice(-50); // Keep last 50 points

      return {
        ...currentStocks,
        [symbol]: {
          ...existingStock, // Keep any other properties not in payload
          ...payload,       // Update with new data from payload
          history: newHistory,
        }
      };
    });
  });
}

export function pingServer(payload = { message: "ping from Svelte" }) {
  if (channel && channel.state === 'joined') {
    console.log('Sending ping to server:', payload);
    channel.push('ping', payload)
      .receive('ok', () => console.log('Ping sent successfully'))
      .receive('error', resp => console.error('Ping failed', resp))
      .receive('timeout', () => console.warn('Ping timed out'));
  } else {
    console.error('Cannot send ping: Channel not joined or not available.');
    if (!socket || socket.connectionState() !== 'open') {
        console.warn('Socket not connected. Attempting to reconnect...');
        connectToSocket(); // Attempt to reconnect if socket is down
    } else if (!channel || channel.state !== 'joined') {
        console.warn('Channel not joined. Attempting to join channel...');
        joinStockChannel();
    }
  }
}

export function disconnectSocket() {
  if (channel) {
    channel.leave()
      .receive('ok', () => console.log('Left channel successfully.'))
      .receive('error', () => console.log('Failed to leave channel.'));
  }
  if (socket) {
    socket.disconnect(() => console.log('Socket disconnected.'));
  }
  socket = null;
  channel = null;
  connectionStatus.set('disconnected');
  lastPong.set(null);
}
