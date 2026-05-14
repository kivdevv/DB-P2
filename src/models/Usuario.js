const supabase = require('../config/db');
const bcrypt = require('bcrypt');

class Usuario {

    /**
     * Crear nuevo usuario (Registro)
     * @param {Object} datos - {correo, contraseña, nombre_completo, cedula, rol}
     */
    static async crearUsuario(datos) {
        try {
            if (!datos.correo || !datos.contraseña || !datos.nombre_completo) {
                throw new Error('Campos requeridos: correo, contraseña, nombre_completo');
            }

            const regexCorreo = /^[^\s@]+@[^\s@]+\.[^\s@]+$/;
            if (!regexCorreo.test(datos.correo)) {
                throw new Error('Correo inválido');
            }

            if (datos.contraseña.length < 8) {
                throw new Error('Contraseña debe tener al menos 8 caracteres');
            }
            if (!/[A-Z]/.test(datos.contraseña)) {
                throw new Error('Contraseña debe incluir al menos una mayúscula');
            }
            if (!/[0-9]/.test(datos.contraseña)) {
                throw new Error('Contraseña debe incluir al menos un número');
            }

            const contraseña_hash = await bcrypt.hash(datos.contraseña, 10);

            const { data, error } = await supabase
                .from('usuario')
                .insert({
                    correo: datos.correo.toLowerCase(),
                    contraseña_hash: contraseña_hash,
                    nombre_completo: datos.nombre_completo,
                    cedula: datos.cedula || null,
                    estado: 'Activo'
                })
                .select();

            if (error) {
                if (error.message.includes('duplicate key')) {
                    throw new Error('El correo ya está registrado');
                }
                throw error;
            }

            if (datos.rol) {
                await this.asignarRol(data[0].id_usuario, datos.rol);
            }

            return {
                exito: true,
                usuario: {
                    id: data[0].id_usuario,
                    correo: data[0].correo,
                    nombre: data[0].nombre_completo
                }
            };

        } catch (err) {
            return {
                exito: false,
                error: err.message
            };
        }
    }

    static async obtenerPorCorreo(correo) {
        try {
            const { data, error } = await supabase
                .from('usuario')
                .select('*')
                .eq('correo', correo.toLowerCase())
                .single();

            if (error) throw new Error(`Usuario no encontrado`);
            if (data.estado === 'Inactivo') throw new Error('Usuario inactivo');
            if (data.estado === 'Suspendido') throw new Error('Usuario suspendido');

            return data;

        } catch (err) {
            throw err;
        }
    }

    static async validarContraseña(contraseña_ingresada, contraseña_hash) {
        return await bcrypt.compare(contraseña_ingresada, contraseña_hash);
    }

    static async obtenerRoles(id_usuario) {
        try {
            const { data, error } = await supabase
                .from('usuario_rol')
                .select(`
                    id_rol,
                    rol:id_rol (
                        id_rol,
                        nombre_rol,
                        nivel_acceso
                    )
                `)
                .eq('id_usuario', id_usuario)
                .is('fecha_fin', null);

            if (error) throw error;

            return data.map(ur => ({
                id_rol: ur.id_rol,
                nombre_rol: ur.rol.nombre_rol,
                nivel_acceso: ur.rol.nivel_acceso
            }));

        } catch (err) {
            throw err;
        }
    }

    static async obtenerPermisos(id_usuario) {
        try {
            const { data, error } = await supabase
                .from('usuario_rol')
                .select(`
                    id_rol,
                    rol_permiso (
                        permiso:id_permiso (
                            codigo_accion,
                            modulo,
                            recurso,
                            accion
                        )
                    )
                `)
                .eq('id_usuario', id_usuario)
                .is('fecha_fin', null);

            if (error) throw error;

            const permisos = new Set();
            data.forEach(ur => {
                ur.rol_permiso.forEach(rp => {
                    permisos.add(rp.permiso.codigo_accion);
                });
            });

            return Array.from(permisos);

        } catch (err) {
            throw err;
        }
    }

    static async asignarRol(id_usuario, nombre_rol, asignado_por = null) {
        try {
            const { data: rol_data, error: rol_error } = await supabase
                .from('rol')
                .select('id_rol')
                .eq('nombre_rol', nombre_rol)
                .single();

            if (rol_error) throw new Error(`Rol ${nombre_rol} no encontrado`);

            const { error } = await supabase
                .from('usuario_rol')
                .insert({
                    id_usuario,
                    id_rol: rol_data.id_rol,
                    asignado_por: asignado_por
                });

            if (error) {
                if (error.message.includes('duplicate')) {
                    throw new Error('El usuario ya tiene ese rol');
                }
                throw error;
            }

            return { exito: true };

        } catch (err) {
            throw err;
        }
    }


    static async tienePermiso(id_usuario, codigo_permiso) {
        try {
            const permisos = await this.obtenerPermisos(id_usuario);
            return permisos.includes(codigo_permiso);

        } catch (err) {
            return false;
        }
    }

    static async listarTodos() {
        try {
            const { data, error } = await supabase
                .from('usuario')
                .select(`
                    id_usuario,
                    correo,
                    nombre_completo,
                    estado,
                    fecha_creacion,
                    usuario_rol (
                        rol:id_rol (nombre_rol)
                    )
                `)
                .order('fecha_creacion', { ascending: false });

            if (error) throw error;

            return data.map(u => ({
                id: u.id_usuario,
                correo: u.correo,
                nombre: u.nombre_completo,
                estado: u.estado,
                roles: u.usuario_rol.map(ur => ur.rol.nombre_rol),
                fecha_creacion: u.fecha_creacion
            }));

        } catch (err) {
            throw err;
        }
    }

    static async cambiarContraseña(id_usuario, contraseña_actual, contraseña_nueva) {
        try {
            const { data: usuario, error: error1 } = await supabase
                .from('usuario')
                .select('contraseña_hash')
                .eq('id_usuario', id_usuario)
                .single();

            if (error1) throw error1;

            const valida = await bcrypt.compare(contraseña_actual, usuario.contraseña_hash);
            if (!valida) throw new Error('Contraseña actual incorrecta');

            const nuevo_hash = await bcrypt.hash(contraseña_nueva, 10);

            const { error: error2 } = await supabase
                .from('usuario')
                .update({
                    contraseña_hash: nuevo_hash,
                    fecha_actualizacion: new Date().toISOString()
                })
                .eq('id_usuario', id_usuario);

            if (error2) throw error2;

            return { exito: true, mensaje: 'Contraseña actualizada' };

        } catch (err) {
            throw err;
        }
    }

    static async desactivarUsuario(id_usuario) {
        try {
            const { error } = await supabase
                .from('usuario')
                .update({ estado: 'Inactivo' })
                .eq('id_usuario', id_usuario);

            if (error) throw error;
            return { exito: true };

        } catch (err) {
            throw err;
        }
    }
}

module.exports = Usuario;