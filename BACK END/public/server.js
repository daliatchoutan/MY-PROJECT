const path = require('path');
const express = require('express');

const app = express();

// Serve static assets from public folder
app.use(express.static(__dirname));

// Client-side fallback to index.html for Flutter Web SPA
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
