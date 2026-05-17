const Asambleista = require('../models/Asambleista');

async function listarAsambleistas(req, res) {
    try {
        const asambleistas = await Asambleista.listarAsambleistas();

        res.status(200).json(asambleistas);
    } catch (error) {
        res.status(500).json({
            error: 'Error al listar asambleistas',
            detalle: error.message
        });
    }
}

async function obtenerAsambleista(req, res) {
    try {
        const { id } = req.params;

        const asambleista = await Asambleista.obtenerAsambleistaPorId(id);

        if (!asambleista) {
            return res.status(404).json({
                error: 'Asambleista no encontrado'
            });
        }

        res.status(200).json(asambleista);

    } catch (error) {
        res.status(500).json({
            error: 'Error al obtener asambleista',
            detalle: error.message
        });
    }
}

async function crearAsambleista(req, res) {
    try {
        const nuevoAsambleista = await Asambleista.crearAsambleista(req.body);

        res.status(201).json(nuevoAsambleista);

    } catch (error) {
        res.status(500).json({
            error: 'Error al crear asambleista',
            detalle: error.message
        });
    }
}

// Issue 3
async function buscarAsambleistas(req, res) {

    try {

        const filtros = {
            busqueda: req.query.busqueda,
            fecha_inicio: req.query.fecha_inicio,
            fecha_fin: req.query.fecha_fin
        };

        if (
            filtros.fecha_inicio &&
            filtros.fecha_fin &&
            filtros.fecha_inicio > filtros.fecha_fin
        ) {

            return res.status(400).json({
                error: 'La fecha inicio no puede ser mayor a la fecha fin'
            });
        }

        const resultados =
            await Asambleista.filtrarAsambleistas(filtros);

        res.status(200).json(resultados);

    } catch (error) {

        res.status(500).json({
            error: 'Error al filtrar asambleistas',
            detalle: error.message
        });
    }
}

module.exports = {
    listarAsambleistas,
    obtenerAsambleista,
    crearAsambleista,
    buscarAsambleistas
};