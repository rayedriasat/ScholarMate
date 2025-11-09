// vercel.config.js
/** @type {import('vercel').VercelConfig} */
module.exports = {
  rewrites: async () => [
    {
      source: '/(.*)',
      destination: '/index.html',
    },
  ],
};