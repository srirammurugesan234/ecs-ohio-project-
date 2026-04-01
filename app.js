const express = require('express');
const app = express();
const PORT = 3000;

app.get('/', (req, res) => {
  res.send('<h1>Welcome!</h1><p>demo completed successfully.</p>');
});

app.listen(PORT, () => console.log(`Server started on port ${PORT}`));