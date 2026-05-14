const supabase = require('../config/db');

async function listarReglamentos() {
    const { data, error } = await supabase
        .from('reglamento')
        .select('id_reglamento, nombre_normativa, sigla, emisor, fecha_registro')
        .order('nombre_normativa');
    if (error) throw error;
    return data;
}

async function obtenerReglamento(idReglamento) {
    const { data, error } = await supabase
        .from('reglamento')
        .select('id_reglamento, nombre_normativa, sigla, emisor, fecha_registro')
        .eq('id_reglamento', idReglamento)
        .maybeSingle();
    if (error) throw error;
    return data;
}

async function listarElementosVigentesPorReglamento(idReglamento) {
    const { data, error } = await supabase
        .from('elemento_normativo')
        .select(`
            id_elemento,
            id_elemento_padre,
            numero_etiqueta,
            contenido_texto,
            orden,
            fecha_inicio_vigencia,
            nivel:catalogo_maestro!elemento_normativo_id_nivel_reglamento_fkey (nombre),
            estado:catalogo_maestro!elemento_normativo_id_estado_vigencia_fkey (nombre)
        `)
        .eq('id_reglamento', idReglamento)
        .is('fecha_fin_vigencia', null)
        .order('id_elemento_padre')
        .order('orden');
    if (error) throw error;
    return data;
}

async function obtenerElementoPorId(idElemento) {
    const { data, error } = await supabase
        .from('elemento_normativo')
        .select(`
            id_elemento,
            id_reglamento,
            id_elemento_padre,
            numero_etiqueta,
            contenido_texto,
            orden,
            fecha_inicio_vigencia,
            fecha_fin_vigencia,
            nivel:catalogo_maestro!elemento_normativo_id_nivel_reglamento_fkey (nombre),
            estado:catalogo_maestro!elemento_normativo_id_estado_vigencia_fkey (nombre)
        `)
        .eq('id_elemento', idElemento)
        .maybeSingle();
    if (error) throw error;
    return data;
}

async function listarVersionesDeElemento(idReglamento, idElementoPadre, numeroEtiqueta) {
    let query = supabase
        .from('elemento_normativo')
        .select(`
            id_elemento,
            id_elemento_padre,
            numero_etiqueta,
            contenido_texto,
            orden,
            fecha_inicio_vigencia,
            fecha_fin_vigencia,
            nivel:catalogo_maestro!elemento_normativo_id_nivel_reglamento_fkey (nombre),
            estado:catalogo_maestro!elemento_normativo_id_estado_vigencia_fkey (nombre)
        `)
        .eq('id_reglamento', idReglamento)
        .eq('numero_etiqueta', numeroEtiqueta)
        .order('fecha_inicio_vigencia', { ascending: false });

    // Los elementos raiz tienen id_elemento_padre NULL; .is() y .eq() son mutuamente excluyentes
    if (idElementoPadre === null || idElementoPadre === undefined) {
        query = query.is('id_elemento_padre', null);
    } else {
        query = query.eq('id_elemento_padre', idElementoPadre);
    }

    const { data, error } = await query;
    if (error) throw error;
    return data;
}

module.exports = {
    listarReglamentos,
    obtenerReglamento,
    listarElementosVigentesPorReglamento,
    obtenerElementoPorId,
    listarVersionesDeElemento,
};