const express = require('express');

const router = express.Router();

const SecretariaController =
require('../controllers/SecretariaController');

router.get(
    '/',
    SecretariaController.listarAsambleistas
);

router.post(
    '/',
    SecretariaController.crearAsambleista
);

router.get(
    '/buscar',
    SecretariaController.buscarAsambleistas
);

module.exports = router;