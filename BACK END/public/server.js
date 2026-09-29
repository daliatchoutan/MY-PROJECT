const path = require('path');
const express = require('express');

const app = express();
const RAILWAY_BACKEND = 'https://my-project-production-f607.up.railway.app';

// Forward API and upload requests directly to central Railway backend
app.use(['/api', '/uploads'], (req, res) => {
  res.redirect(307, `${RAILWAY_BACKEND}${req.originalUrl}`);
});

// Serve static assets from this public folder
app.use(express.static(__dirname));

// Fallback to index.html for Flutter Web SPA client-side routing
app.get('*', (req, res) => {
  res.sendFile(path.join(__dirname, 'index.html'));
});

if (require.main === module) {
  const PORT = process.env.PORT || 3000;
  app.listen(PORT, () => {
    console.log(`NOVARA Flutter Web listening on port ${PORT}`);
  });
}

module.exports = app;
