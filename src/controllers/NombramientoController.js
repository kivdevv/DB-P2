const Nombramiento = require('../models/Nombramiento');

class NombramientoController {

static async crear(req, res) {
try {
    // Verificar permisos (solo Editor+)
    if (!['Admin', 'Editor'].includes(req.usuario.rol)) {
    return res.status(403).json({
        error: 'Solo Admin o Editor pueden crear nombramientos'
    });
    }

    const { id_asambleista, id_sector, fecha_inicio, fecha_fin } = req.body;

    const resultado = await Nombramiento.crearNombramiento({
    id_asambleista,
    id_sector,
    fecha_inicio,
    fecha_fin
    });

    if (!resultado.exito) {
    return res.status(400).json({
        error: resultado.error
    });
    }

    return res.status(201).json({
    mensaje: 'Nombramiento creado exitosamente',
    nombramiento: resultado.nombramiento
    });

} catch (err) {
    res.status(500).json({
    error: err.message
    });
}
}

static async obtenerHistorial(req, res) {
try {
    const { id_asambleista } = req.params;

    const historial = await Nombramiento.obtenerHistorialAsambleista(id_asambleista);

    if (historial.error) {
    return res.status(404).json({
        error: historial.error
    });
    }

    return res.status(200).json({
    id_asambleista,
    nombramientos: historial,
    total: historial.length
    });

} catch (err) {
    res.status(500).json({
    error: err.message
    });
}
}

static async obtenerActual(req, res) {
try {
    const { id_asambleista } = req.params;

    const resultado = await Nombramiento.obtenerActual(id_asambleista);

    if (resultado.error) {
    return res.status(404).json({
        error: resultado.error
    });
    }

    return res.status(200).json(resultado);

} catch (err) {
    res.status(500).json({
    error: err.message
    });
}
}

static async finalizar(req, res) {
try {
    // Solo Admin puede finalizar
    if (req.usuario.rol !== 'Admin') {
    return res.status(403).json({
        error: 'Solo Admin puede finalizar nombramientos'
    });
    }

    const { id_nombramiento } = req.params;
    const { fecha_fin } = req.body;

    const resultado = await Nombramiento.finalizarNombramiento(id_nombramiento, fecha_fin);

    if (!resultado.exito) {
    return res.status(400).json({
        error: resultado.error
    });
    }

    return res.status(200).json({
    mensaje: 'Nombramiento finalizado',
    nombramiento: resultado.nombramiento
    });

} catch (err) {
    res.status(500).json({
    error: err.message
    });
}
}
}

module.exports = NombramientoController;