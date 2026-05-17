const Catalogo = require('../models/Catalogo');

async function obtenerSectores(req, res) {

    try {

        const sectores =
        await Catalogo.obtenerCatalogo('SECTOR');

        res.status(200).json(sectores);

    } catch (error) {

        res.status(500).json({
            error: 'Error al obtener sectores',
            detalle: error.message
        });
    }
}

async function obtenerPuestos(req, res) {

    try {

        const puestos =
        await Catalogo.obtenerCatalogo('PUESTO');

        res.status(200).json(puestos);

    } catch (error) {

        res.status(500).json({
            error: 'Error al obtener puestos',
            detalle: error.message
        });
    }
}

async function obtenerTiposSesion(req, res) {

    try {

        const tiposSesion =
        await Catalogo.obtenerCatalogo('TIPO_SESION');

        res.status(200).json(tiposSesion);

    } catch (error) {

        res.status(500).json({
            error: 'Error al obtener tipos de sesion',
            detalle: error.message
        });
    }
}

async function obtenerTiposModalidad(req, res) {

    try {

        const tiposModalidad =
        await Catalogo.obtenerCatalogo('TIPO_MODALIDAD');

        res.status(200).json(tiposModalidad);

    } catch (error) {

        res.status(500).json({
            error: 'Error al obtener tipos de modalidad',
            detalle: error.message
        });
    }
}

module.exports = {
    obtenerSectores,
    obtenerPuestos,
    obtenerTiposSesion,
    obtenerTiposModalidad
};