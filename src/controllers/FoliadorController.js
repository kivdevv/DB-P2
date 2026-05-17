const Foliado = require('../models/Foliado');

class FoliadorController {

static async generarFolio(req, res) {
try {
    const resultado = await Foliado.generarFolioUnico();

    if (!resultado.exito) {
    return res.status(400).json({
        error: resultado.error
    });
    }

    return res.status(200).json({
    mensaje: 'Folio generado exitosamente',
    folio: resultado.folio,
    numero_secuencial: resultado.numero_secuencial,
    año: resultado.año,
    timestamp: new Date().toISOString()
    });

} catch (err) {
    res.status(500).json({
    error: 'Error interno: ' + err.message
    });
}
}

static async obtenerUltimo(req, res) {
try {
    const año = req.query.año ? parseInt(req.query.año) : null;
    const resultado = await Foliado.obtenerUltimoFolio(año);

    return res.status(200).json(resultado);

} catch (err) {
    res.status(500).json({
    error: err.message
    });
}
}


static async obtenerHistorial(req, res) {
try {
    if (req.usuario.rol !== 'Admin') {
    return res.status(403).json({
        error: 'Solo Admin puede ver historial de folios'
    });
    }

    const año = req.query.año ? parseInt(req.query.año) : null;
    const historial = await Foliado.obtenerHistorial(año);

    return res.status(200).json({
    historial: historial,
    total_registros: historial.length
    });

} catch (err) {
    res.status(500).json({
    error: err.message
    });
}
}
}

module.exports = FoliadorController;