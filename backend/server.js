require("dotenv").config();
var express = require('express');
var cors = require('cors');

const app = express();
app.use(cors());
app.use(express.json());

app.use('/api/auth', require('./routes/auth'));

app.get('/', (req, res) => {
  res.send('Backend is running');
});

app.listen(3000, '0.0.0.0', () => {
  console.log('Backend server is running at http://localhost:3000');
});