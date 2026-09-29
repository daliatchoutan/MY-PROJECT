const path = require('path');
const express = require('express');

const app = express();
const publicDir = path.join(__dirname, 'BACK END', 'public');

app.use(express.static(publicDir));

app.get('*', (req, res) => {
  res.sendFile(path.join(publicDir, 'index.html'));
});

if (require.main === module) {
  const PORT = process.env.PORT || 3000;
  app.listen(PORT, () => {
    console.log(`NOVARA Flutter Web listening on port ${PORT}`);
  });
}

module.exports = app;
