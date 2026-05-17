const supabase = require('../config/db');

class Nombramiento {

static async crearNombramiento(datos) {
try {
    const {
    id_asambleista,
    id_sector,
    fecha_inicio,
    fecha_fin
    } = datos;

    // Validar fechas
    if (new Date(fecha_inicio) > new Date(fecha_fin || new Date())) {
    throw new Error('La fecha de inicio no puede ser posterior a la fecha de fin');
    }

    const { data, error } = await supabase
    .from('nombramiento')
    .insert({
        id_asambleista,
        id_sector,
        fecha_inicio,
        fecha_fin: fecha_fin || null,
        estado: 'Activo'
    })
    .select();

    if (error) throw error;

    return {
    exito: true,
    nombramiento: data[0]
    };

} catch (err) {
    return {
    exito: false,
    error: err.message
    };
}
}

static async obtenerHistorialAsambleista(id_asambleista) {
try {
    const { data, error } = await supabase
    .from('nombramiento')
    .select(`
        *,
        sector:id_sector (nombre_sector)
    `)
    .eq('id_asambleista', id_asambleista)
    .order('fecha_inicio', { ascending: false });

    if (error) throw error;

    return data.map(n => ({
    id_nombramiento: n.id_nombramiento,
    sector: n.sector.nombre_sector,
    fecha_inicio: n.fecha_inicio,
    fecha_fin: n.fecha_fin,
    estado: n.estado,
    es_activo: !n.fecha_fin || new Date(n.fecha_fin) >= new Date()
    }));

} catch (err) {
    return {
    error: err.message
    };
}
}

static async obtenerActual(id_asambleista) {
try {
    const hoy = new Date().toISOString().split('T')[0];

    const { data, error } = await supabase
    .from('nombramiento')
    .select(`
        *,
        sector:id_sector (nombre_sector)
    `)
    .eq('id_asambleista', id_asambleista)
    .eq('estado', 'Activo')
    .lte('fecha_inicio', hoy)
    .or(`fecha_fin.is.null,fecha_fin.gte.${hoy}`)
    .single();

    if (error) return { error: 'Sin nombramiento activo' };

    return {
    id_nombramiento: data.id_nombramiento,
    sector: data.sector.nombre_sector,
    fecha_inicio: data.fecha_inicio,
    fecha_fin: data.fecha_fin
    };

} catch (err) {
    return {
    error: err.message
    };
}
}

static async finalizarNombramiento(id_nombramiento, fecha_fin = null) {
try {
    const { data, error } = await supabase
    .from('nombramiento')
    .update({
        estado: 'Histórico',
        fecha_fin: fecha_fin || new Date().toISOString().split('T')[0]
    })
    .eq('id_nombramiento', id_nombramiento)
    .select();

    if (error) throw error;

    return {
    exito: true,
    nombramiento: data[0]
    };

} catch (err) {
    return {
    exito: false,
    error: err.message
    };
}
}
}

module.exports = Nombramiento;