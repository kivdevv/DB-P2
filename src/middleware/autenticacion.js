const jwt = require('jsonwebtoken');


function verificarJWT(req, res, next) {
    try {
        const token = req.headers.authorization?.split(' ')[1];

        if (!token) {
            return res.status(401).json({
                error: 'No autorizado. Token requerido.'
            });
        }

        const payload = jwt.verify(token, process.env.JWT_SECRET);

        req.usuario = payload;

        next();

    } catch (err) {
        return res.status(401).json({
            error: 'Token inválido o expirado'
        });
    }
}

/**
 * Middleware: Verificar rol
 * @param {Array<String>} rolesPermitidos - Ej: ['Admin', 'Editor']
 */
function verificarRol(...rolesPermitidos) {
    return (req, res, next) => {
        if (!req.usuario) {
            return res.status(401).json({
                error: 'No autenticado'
            });
        }

        if (!rolesPermitidos.includes(req.usuario.rol)) {
            return res.status(403).json({
                error: 'No tienes permisos para esta acción'
            });
        }

        next();
    };
}

module.exports = {
    verificarJWT,
    verificarRol
};