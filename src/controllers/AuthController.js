const Usuario = require('../models/Usuario');
const jwt = require('jsonwebtoken');

class AuthController {


    static async registro(req, res) {
        try {
            const { correo, contraseña} = req.body;

            const es_correo_valido = /^[^\s@]+@[^\s@]+\.[^\s@]+$/.test(correo);
            if (!es_correo_valido) {
                return res.status(400).json({
                    error: 'Correo inválido'
                });
            }

            if (contraseña.length < 8) {
                return res.status(400).json({
                    error: 'Contraseña debe tener al menos 8 caracteres'
                });
            }

            const resultado = await Usuario.crearUsuario({
                correo,
                contraseña,
                rol: 'Consulta' 
            });

            if (!resultado.exito) {
                return res.status(400).json({
                    error: resultado.error
                });
            }

            const token = jwt.sign(
                {
                    id_usuario: resultado.usuario.id_usuario,
                    correo: resultado.usuario.correo,
                    rol: resultado.usuario.rol
                },
                process.env.JWT_SECRET,
                { expiresIn: '24h' }
            );

            return res.status(201).json({
                mensaje: 'Registro exitoso',
                token: token,
                usuario: {
                    id: resultado.usuario.id_usuario,
                    correo: resultado.usuario.correo,
                    rol: resultado.usuario.rol
                }
            });

        } catch (err) {
            res.status(500).json({
                error: 'Error interno: ' + err.message
            });
        }
    }

    static async login(req, res) {
        try {
            const { correo, contraseña } = req.body;

            const usuario = await Usuario.obtenerPorCorreo(correo);

            if (!usuario) {
                return res.status(401).json({ error: 'Correo o contraseña incorrecta' });
            }

            const contraseña_valida = await Usuario.validarContraseña(
                contraseña,
                usuario.contraseña_hash
            );

            if (!contraseña_valida) {
                return res.status(401).json({ error: 'Correo o contraseña incorrecta' });
            }

            const roles = await Usuario.obtenerRoles(usuario.id_usuario);
            const rol_usuario = roles.length > 0 ? roles[0].nombre_rol : 'Consulta';

            const token = jwt.sign(
                {
                    id_usuario: usuario.id_usuario,
                    correo: usuario.correo,
                    rol: rol_usuario 
                },
                process.env.JWT_SECRET,
                { expiresIn: '24h' }
            );

            return res.status(200).json({
                mensaje: 'Sesión iniciada',
                token: token,
                usuario: {
                    id: usuario.id_usuario,
                    correo: usuario.correo,
                    rol: rol_usuario
                }
            });

        } catch (err) {
            res.status(500).json({ error: 'Error interno: ' + err.message });
        }
    }
    

    static async logout(req, res) {

        return res.status(200).json({
            mensaje: 'Sesión cerrada exitosamente'
        });
    }

    static async obtenerPerfil(req, res) {
        try {
            const usuario = req.usuario;

            const datos = await Usuario.obtenerPorCorreo(usuario.correo);

            return res.status(200).json({
                usuario: {
                    id: datos.id_usuario,
                    correo: datos.correo,
                    rol: datos.rol,
                    estado: datos.estado
                }
            });

        } catch (err) {
            res.status(500).json({
                error: err.message
            });
        }
    }

    static async cambiarContraseña(req, res) {
        try {
            const { contraseña_actual, contraseña_nueva } = req.body;
            const id_usuario = req.usuario.id_usuario;

            const resultado = await Usuario.cambiarContraseña(
                id_usuario,
                contraseña_actual,
                contraseña_nueva
            );

            return res.status(200).json(resultado);

        } catch (err) {
            res.status(400).json({ error: err.message });
        }
    }

    static async obtenerPermisos(req, res) {
        try {
            const id_usuario = req.usuario.id_usuario;
            const permisos = await Usuario.obtenerPermisos(id_usuario);

            return res.status(200).json({
                id_usuario,
                permisos,
                total: permisos.length
            });

        } catch (err) {
            res.status(500).json({ error: err.message });
        }
    }
}

module.exports = AuthController;
