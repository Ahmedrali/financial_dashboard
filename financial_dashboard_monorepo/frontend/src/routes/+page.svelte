<script>
  import { onMount, onDestroy } from 'svelte';
  import { connectToSocket, disconnectSocket, pingServer, connectionStatus, lastPong } from '$lib/phoenixSocket.js';

  onMount(() => {
    connectToSocket();
  });

  onDestroy(() => {
    disconnectSocket();
  });

  function handlePing() {
    pingServer({ data: "Hello from Svelte on " + new Date().toLocaleTimeString() });
  }
</script>

<main>
  <h1>Real-Time Financial Dashboard</h1>
  
  <section>
    <h2>WebSocket Connection</h2>
    <p>Status: {$connectionStatus}</p>
    {#if $connectionStatus === 'connected'}
      <button on:click={handlePing}>Send Ping</button>
    {:else if $connectionStatus === 'error' || $connectionStatus === 'closed' || $connectionStatus === 'disconnected'}
      <button on:click={connectToSocket}>Reconnect</button>
    {/if}
  </section>

  {#if $lastPong}
    <section>
      <h2>Last Pong Received:</h2>
      <pre>{JSON.stringify($lastPong, null, 2)}</pre>
    </section>
  {/if}

  <p>Visit <a href="https://svelte.dev/docs/kit">svelte.dev/docs/kit</a> to read the SvelteKit documentation.</p>
</main>

<style>
  main {
    font-family: sans-serif;
    padding: 1em;
  }
  section {
    margin-bottom: 1em;
    padding: 1em;
    border: 1px solid #eee;
    border-radius: 4px;
  }
  pre {
    background-color: #f4f4f4;
    padding: 0.5em;
    border-radius: 4px;
    overflow-x: auto;
  }
</style>
