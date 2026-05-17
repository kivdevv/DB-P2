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

/**
 * Middleware: Verificar que usuario tenga permiso específico (GRANULAR)
 * Uso: app.post('/ruta', verificarPermiso('ASAMBLEISTA_CREAR'), controlador)
 */
function verificarPermiso(...permisos_requeridos) {
    return (req, res, next) => {
        if (!req.usuario) {
            return res.status(401).json({ error: 'No autenticado' });
        }

        const tienePermiso = req.usuario.permisos && 
            permisos_requeridos.some(p => req.usuario.permisos.includes(p));

        if (!tienePermiso) {
            return res.status(403).json({
                error: `Permiso insuficiente. Se requiere: ${permisos_requeridos.join(' O ')}`
            });
        }

        next();
    };
}

/**
 * Middleware: Verificar nivel de acceso (numérico)
 */
function verificarNivelAcceso(nivel_minimo) {
    return (req, res, next) => {
        if (!req.usuario) {
            return res.status(401).json({ error: 'No autenticado' });
        }

        if (!req.usuario.nivel_acceso || req.usuario.nivel_acceso < nivel_minimo) {
            return res.status(403).json({
                error: `Nivel de acceso insuficiente. Se requiere nivel ${nivel_minimo} o superior.`
            });
        }

        next();
    };
}

/**
 * Middleware: Limitar intentos de login fallidos
 */
async function limitarIntentos(max_intentos = 5, ventana_minutos = 15) {
    return async (req, res, next) => {
        const ip = req.ip;
        const supabase = require('../config/db');

        try {
            const hace_X_minutos = new Date(Date.now() - ventana_minutos * 60000);

            const { data, error } = await supabase
                .from('intento_login_fallido')
                .select('id_intento')
                .eq('ip_origen', ip)
                .gte('timestamp', hace_X_minutos.toISOString());

            if (error) throw error;

            if (data && data.length >= max_intentos) {
                return res.status(429).json({
                    error: `Demasiados intentos fallidos. Intenta en ${ventana_minutos} minutos.`,
                    reintenta_en_segundos: ventana_minutos * 60
                });
            }

            next();

        } catch (err) {
            console.error('Error en limitarIntentos:', err);
            next();
        }
    };
}

module.exports = {
    verificarJWT,
    verificarRol,
    verificarPermiso,
    verificarNivelAcceso,
    limitarIntentos
};