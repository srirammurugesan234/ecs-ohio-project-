const express = require('express');
const app = express();
const PORT = 3000;

app.get('/', (req, res) => {
  res.send('<h1>Success!</h1><p>Running on AWS ECS Fargate in Ohio 1.</p>');
});

app.listen(PORT, () => console.log(`Server started on port ${PORT}`));