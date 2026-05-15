const express = require('express');

const router = express.Router();

const CatalogoController =
require('../controllers/CatalogoController');

router.get(
    '/catalogos/sectores',
    CatalogoController.obtenerSectores
);

router.get(
    '/catalogos/puestos',
    CatalogoController.obtenerPuestos
);

router.get(
    '/catalogos/tipos-sesion',
    CatalogoController.obtenerTiposSesion
);

router.get(
    '/catalogos/tipos-modalidad',
    CatalogoController.obtenerTiposModalidad
);

module.exports = router;