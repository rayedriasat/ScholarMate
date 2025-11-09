/**
 * Configuration loader for ScholarMate
 * Fetches environment variables from Vercel serverless function in production
 * or uses local .env file in development
 */
(function() {
  window.scholarMateConfig = null;
  window.scholarMateConfigLoaded = false;
  window.scholarMateConfigError = null;

  /**
   * Load configuration from Vercel API endpoint
   */
  async function loadConfig() {
    try {
      // Check if running on localhost (development)
      const isLocalhost = window.location.hostname === 'localhost' || 
                         window.location.hostname === '127.0.0.1' ||
                         window.location.hostname === '';

      if (isLocalhost) {
        // In development, Flutter will use .env file via flutter_dotenv
        // Set a flag so Flutter knows to use dotenv
        window.scholarMateConfig = {
          useLocalEnv: true
        };
        window.scholarMateConfigLoaded = true;
        console.log('Running locally - using .env file');
        return;
      }

      // In production (Vercel), fetch from serverless function
      const response = await fetch('/api/config');
      
      if (!response.ok) {
        throw new Error(`Failed to load config: ${response.status} ${response.statusText}`);
      }

      const config = await response.json();
      window.scholarMateConfig = config;
      window.scholarMateConfigLoaded = true;
      console.log('Configuration loaded from Vercel');
    } catch (error) {
      console.error('Error loading configuration:', error);
      window.scholarMateConfigError = error.message;
      window.scholarMateConfigLoaded = true; // Mark as loaded even on error
      
      // Set empty config as fallback
      window.scholarMateConfig = {
        GOOGLE_CLIENT_ID: '',
        GOOGLE_CLIENT_SECRET: '',
        GOOGLE_REDIRECT_URI: '',
        API_BASE_URL: '',
        SUPABASE_URL: '',
        SUPABASE_ANON_KEY: '',
      };
    }
  }

  // Load config immediately
  loadConfig();
})();
