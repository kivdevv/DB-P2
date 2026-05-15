const supabase = require('../config/db');

async function listarAsambleistas() {
    const { data, error } = await supabase
        .from('asambleista')
        .select(`
            id_asambleista,
            nombre_completo,
            cedula,
            correo,
            foto_url,
            activo,
            fecha_registro
        `)
        .order('nombre_completo');

    if (error) throw error;
    return data;
}

async function obtenerAsambleistaPorId(idAsambleista) {
    const { data, error } = await supabase
        .from('asambleista')
        .select(`
            id_asambleista,
            nombre_completo,
            cedula,
            correo,
            foto_url,
            activo,
            fecha_registro
        `)
        .eq('id_asambleista', idAsambleista)
        .maybeSingle();

    if (error) throw error;
    return data;
}

async function crearAsambleista(asambleista) {
    const { data, error } = await supabase
        .from('asambleista')
        .insert([asambleista])
        .select()
        .maybeSingle();

    if (error) throw error;
    return data;
}

module.exports = {
    listarAsambleistas,
    obtenerAsambleistaPorId,
    crearAsambleista,
};