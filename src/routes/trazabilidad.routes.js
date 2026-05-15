const express = require('express');
const TrazabilidadController = require('../controllers/TrazabilidadController');
const { verificarJWT, verificarPermiso } = require('../middleware/autenticacion');

const router = express.Router();

router.get('/propuestas', verificarJWT, TrazabilidadController.listarPropuestasConEtapa);
router.get('/propuesta/:id', verificarJWT, TrazabilidadController.obtenerTrazabilidadPorPropuesta);
router.get('/clausula/:id', verificarJWT, TrazabilidadController.obtenerClausulaLegal);
router.get('/comisiones', verificarJWT, TrazabilidadController.listarComisionesActivas);
router.post('/participacion', verificarJWT, verificarPermiso('TRAZABILIDAD_REGISTRAR', 'SECRETARIA_DAIR'), TrazabilidadController.registrarParticipacion);

module.exports = router;
