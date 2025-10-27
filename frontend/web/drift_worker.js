// Drift web worker for SQLite on web
// This file is required for Drift to work on web platform

importScripts('sqlite3.wasm.js');

// Initialize the worker
self.addEventListener('message', async (event) => {
  const { type, payload } = event.data;
  
  if (type === 'init') {
    // Initialize SQLite
    try {
      const sqlite3 = await initSqlite3();
      self.postMessage({ type: 'ready' });
    } catch (error) {
      self.postMessage({ type: 'error', error: error.message });
    }
  }
});

// Load SQLite WASM
async function initSqlite3() {
  const sqlite3InitModule = self.sqlite3InitModule;
  if (!sqlite3InitModule) {
    throw new Error('sqlite3InitModule not found');
  }
  return await sqlite3InitModule();
}
