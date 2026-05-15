const supabase = require('../config/db');

async function obtenerTrazabilidadPorPropuesta(idPropuesta) {
    const { data, error } = await supabase
        .from('vw_trazabilidad_propuesta')
        .select('*')
        .eq('id_propuesta', idPropuesta)
        .order('fecha_participacion');
    if (error) throw error;
    return data;
}

async function listarPropuestasConEtapa() {
    const { data, error } = await supabase
        .from('propuesta')
        .select(`
            id_propuesta,
            titulo,
            descripcion,
            fecha_creacion,
            etapa:catalogo_etapas_propuestas!fk_etapa_propuesta (nombre),
            estado:catalogo_estado_propuestas!fk_estado_propuesta (nombre)
        `)
        .order('fecha_creacion', { ascending: false });
    if (error) throw error;
    return data;
}

async function registrarParticipacion({ idPropuesta, idAsambleista, idComision, idEtapa, rol, observaciones }) {
    const { data, error } = await supabase
        .from('participacion_propuesta')
        .insert({
            id_propuesta: idPropuesta,
            id_asambleista: idAsambleista,
            id_comision: idComision ?? null,
            id_etapa_propuesta: idEtapa,
            rol: rol ?? null,
            observaciones: observaciones ?? null
        })
        .select()
        .single();
    if (error) throw error;
    return data;
}

async function obtenerClausulaLegal(idPropuesta) {
    const { data, error } = await supabase
        .rpc('fn_clausula_etapa_procedencia', { p_id_propuesta: idPropuesta });
    if (error) throw error;
    return data;
}

async function listarComisionesActivas() {
    const { data, error } = await supabase
        .from('comision')
        .select(`
            id_comision,
            nombre,
            fecha_creacion,
            activa,
            tipo:catalogo_tipo_comision!fk_comision_tipo (nombre, descripcion)
        `)
        .eq('activa', true)
        .order('nombre');
    if (error) throw error;
    return data;
}

module.exports = {
    obtenerTrazabilidadPorPropuesta,
    listarPropuestasConEtapa,
    registrarParticipacion,
    obtenerClausulaLegal,
    listarComisionesActivas,
};
