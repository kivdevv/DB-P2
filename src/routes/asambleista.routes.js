const express = require('express');

const router = express.Router();

const SecretariaController =
require('../controllers/SecretariaController');

router.get(
    '/buscar',
    SecretariaController.buscarAsambleistas
);

module.exports = router;