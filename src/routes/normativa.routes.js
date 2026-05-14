const express = require('express');
const NormativaController = require('../controllers/NormativaController');

const router = express.Router();

function manejar(controllerFn) {
    return async (req, res) => {
        try {
            const data = await controllerFn(req.params);
            res.json(data);
        } catch (err) {
            const status = err.message?.includes('no encontrado') ? 404 : 500;
            res.status(status).json({ error: err.message });
        }
    };
}

router.get('/api/reglamentos', manejar(() =>
    NormativaController.listarReglamentos()
));

router.get('/api/reglamentos/:idReglamento', manejar(({ idReglamento }) =>
    NormativaController.obtenerReglamento(idReglamento)
));

router.get('/api/reglamentos/:idReglamento/arbol', manejar(({ idReglamento }) =>
    NormativaController.obtenerArbolReglamento(idReglamento)
));

router.get('/api/elementos/:idElemento', manejar(({ idElemento }) =>
    NormativaController.obtenerElementoConTrazabilidad(idElemento)
));

module.exports = router;