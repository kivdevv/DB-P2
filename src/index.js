require('dotenv').config();
const express = require('express');
const path = require('path');

const app = express();
const PORT = process.env.PORT || 3000;

app.use(express.json());
app.use(express.urlencoded({ extended: true }));
app.use(express.static(path.join(__dirname, 'views')));

app.get('/health', (req, res) => {
  res.json({ status: 'ok', servicio: 'AIR', timestamp: new Date().toISOString() });
});

const normativaRoutes = require('./routes/normativa.routes');
app.use(normativaRoutes);

app.listen(PORT, () => {
  console.log(`Servidor AIR escuchando en puerto ${PORT}`);
});
