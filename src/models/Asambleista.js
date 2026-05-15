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

// Issue 3
async function filtrarAsambleistas(filtros) {

    let query = supabase
        .from('asambleista')
        .select('*');

    if (
        filtros.busqueda &&
        filtros.busqueda.trim() !== ''
    ) {

        query = query.or(
            `nombre_completo.ilike.%${filtros.busqueda}%,cedula.ilike.%${filtros.busqueda}%`
        );
    }

    if (
        filtros.fecha_inicio &&
        filtros.fecha_inicio !== ''
    ) {

        query = query.gte(
            'fecha_registro',
            filtros.fecha_inicio
        );
    }

    if (
        filtros.fecha_fin &&
        filtros.fecha_fin !== ''
    ) {

        query = query.lte(
            'fecha_registro',
            filtros.fecha_fin
        );
    }

    const { data, error } =
    await query.order('nombre_completo');

    if (error) throw error;
    console.log(data);
    return data;
}

module.exports = {
    listarAsambleistas,
    obtenerAsambleistaPorId,
    crearAsambleista,
    filtrarAsambleistas
};