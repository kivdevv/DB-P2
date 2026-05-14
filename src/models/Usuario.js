const supabase = require('../config/db');
const bcrypt = require('bcrypt');

class Usuario {

    /**
     * Crear nuevo usuario (Registrar)
     * @param {Object} datos - {correo, contraseña, nombre_completo, rol}
     * @returns {Promise<Object>}
     */
    static async crearUsuario(datos) {
        try {
            if (!datos.correo || !datos.contraseña || !datos.nombre_completo) {
                throw new Error('Campos requeridos: correo, contraseña, nombre_completo');
            }

            const contraseña_hash = await bcrypt.hash(datos.contraseña, 10);

            const { data, error } = await supabase
                .from('usuario')
                .insert({
                    correo: datos.correo,
                    contraseña_hash: contraseña_hash,
                    nombre_completo: datos.nombre_completo,
                    rol: datos.rol || 'Consulta', 
                    fecha_creacion: new Date().toISOString(),
                    estado: 'Activo'
                })
                .select();

            if (error) throw error;

            return {
                exito: true,
                mensaje: 'Usuario creado exitosamente',
                usuario: data[0]
            };

        } catch (err) {
            return {
                exito: false,
                error: err.message
            };
        }
    }

    /**
     * Obtener usuario por correo para procesos de login
     * @param {string} correo 
     */
    static async obtenerPorCorreo(correo) {
        const { data, error } = await supabase
            .from('usuario')
            .select('*')
            .eq('correo', correo)
            .single();

        if (error) throw new Error(`Usuario no encontrado: ${correo}`);
        return data;
    }


    static async validarContraseña(contraseña_ingresada, contraseña_hash) {
        return await bcrypt.compare(contraseña_ingresada, contraseña_hash);
    }

    static async actualizarRol(id_usuario, nuevo_rol) {
        const { data, error } = await supabase
            .from('usuario')
            .update({ rol: nuevo_rol })
            .eq('id_usuario', id_usuario)
            .select();

        if (error) throw error;
        return data[0];
    }

    static async listarTodos() {
        const { data, error } = await supabase
            .from('usuario')
            .select('id_usuario, nombre_completo, correo, rol, estado')
            .order('fecha_creacion', { ascending: false });

        if (error) throw error;
        return data;
    }
}

module.exports = Usuario;