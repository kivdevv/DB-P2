const Trazabilidad = require('../models/Trazabilidad');

async function obtenerTrazabilidadPorPropuesta(req, res) {
    try {
        const id = parseInt(req.params.id);
        if (isNaN(id)) return res.status(400).json({ error: 'ID de propuesta invalido' });

        const data = await Trazabilidad.obtenerTrazabilidadPorPropuesta(id);
        if (!data || data.length === 0) {
            return res.status(404).json({ error: 'No se encontro trazabilidad para esta propuesta' });
        }
        res.json(data);
    } catch (err) {
        console.error(err);
        res.status(500).json({ error: 'Error al obtener trazabilidad' });
    }
}

async function listarPropuestasConEtapa(req, res) {
    try {
        const data = await Trazabilidad.listarPropuestasConEtapa();
        res.json(data);
    } catch (err) {
        console.error(err);
        res.status(500).json({ error: 'Error al listar propuestas' });
    }
}

async function registrarParticipacion(req, res) {
    try {
        const { id_propuesta, id_asambleista, id_comision, id_etapa_propuesta, rol, observaciones } = req.body;

        if (!id_propuesta || !id_asambleista || !id_etapa_propuesta) {
            return res.status(400).json({
                error: 'Faltan campos requeridos: id_propuesta, id_asambleista, id_etapa_propuesta'
            });
        }

        if (isNaN(parseInt(id_propuesta))) {
            return res.status(400).json({ error: 'id_propuesta debe ser un numero entero' });
        }
        if (isNaN(parseInt(id_asambleista))) {
            return res.status(400).json({ error: 'id_asambleista debe ser un numero entero' });
        }
        if (isNaN(parseInt(id_etapa_propuesta))) {
            return res.status(400).json({ error: 'id_etapa_propuesta debe ser un numero entero' });
        }

        const data = await Trazabilidad.registrarParticipacion({
            idPropuesta: parseInt(id_propuesta),
            idAsambleista: parseInt(id_asambleista),
            idComision: id_comision ? parseInt(id_comision) : null,
            idEtapa: parseInt(id_etapa_propuesta),
            rol: rol || null,
            observaciones: observaciones || null
        });

        res.status(201).json(data);
    } catch (err) {
        console.error(err);
        // FK violations from Supabase come as code 23503
        if (err.code === '23503') {
            return res.status(400).json({ error: 'Referencia invalida: propuesta, asambleista o etapa no existen' });
        }
        res.status(500).json({ error: 'Error al registrar participacion' });
    }
}

async function obtenerClausulaLegal(req, res) {
    try {
        const id = parseInt(req.params.id);
        if (isNaN(id)) return res.status(400).json({ error: 'ID de propuesta invalido' });

        const clausula = await Trazabilidad.obtenerClausulaLegal(id);
        res.json({ clausula_legal: clausula });
    } catch (err) {
        console.error(err);
        res.status(500).json({ error: 'Error al obtener clausula legal' });
    }
}

async function listarComisionesActivas(req, res) {
    try {
        const data = await Trazabilidad.listarComisionesActivas();
        res.json(data);
    } catch (err) {
        console.error(err);
        res.status(500).json({ error: 'Error al listar comisiones' });
    }
}

module.exports = {
    obtenerTrazabilidadPorPropuesta,
    listarPropuestasConEtapa,
    registrarParticipacion,
    obtenerClausulaLegal,
    listarComisionesActivas,
};
