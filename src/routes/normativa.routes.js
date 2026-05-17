const express = require('express');
const NormativaController = require('../controllers/NormativaController');
const { verificarJWT, verificarRol } = require('../middleware/autenticacion');
const supabase = require('../config/db');

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

router.post('/api/reglamentos', 
    verificarJWT, 
    verificarRol('Editor', 'Admin'), 
    async (req, res) => {
        try {
            // Inserción REAL en la base de datos de Supabase
            const { data, error } = await supabase
                .from('reglamento')
                .insert([{
                    nombre_normativa: 'Reglamento de Prueba RBAC',
                    sigla: 'RBAC-' + Math.floor(Math.random() * 1000), // Sigla aleatoria para que no choque
                    emisor: 'AIR'
                }])
                .select();

            if (error) throw error;

            return res.status(201).json({ 
                mensaje: 'Reglamento guardado en la Base de Datos',
                reglamento: data[0]
            });
        } catch (err) {
            return res.status(500).json({ error: err.message });
        }
    }
);

module.exports = router;