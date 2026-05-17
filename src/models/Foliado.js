const supabase = require('../config/db');

class Foliado {

/**
 * Generar siguiente folio único (DAIR-XXX-YYYY)
 * Formato: DAIR-[3 dígitos]-[año]
 * Ejemplo: DAIR-001-2026, DAIR-002-2026
 */
static async generarFolioUnico() {
try {
    const año_actual = new Date().getFullYear();

    let { data: control, error: error1 } = await supabase
    .from('control_folio')
    .select('ultimo_numero')
    .eq('año', año_actual)
    .single();

    if (!control) {
    const { data, error: error2 } = await supabase
        .from('control_folio')
        .insert({
        año: año_actual,
        ultimo_numero: 0,
        fecha_actualizacion: new Date().toISOString()
        })
        .select()
        .single();

    if (error2) throw error2;
    control = data;
    }

    const nuevo_numero = control.ultimo_numero + 1;

    const { error: error3 } = await supabase
    .from('control_folio')
    .update({
        ultimo_numero: nuevo_numero,
        fecha_actualizacion: new Date().toISOString()
    })
    .eq('año', año_actual);

    if (error3) throw error3;

    const folio = `DAIR-${String(nuevo_numero).padStart(3, '0')}-${año_actual}`;

    return {
    exito: true,
    folio: folio,
    numero_secuencial: nuevo_numero,
    año: año_actual
    };

} catch (err) {
    return {
    exito: false,
    error: err.message
    };
}
}

static async obtenerUltimoFolio(año = null) {
try {
    const año_consulta = año || new Date().getFullYear();

    const { data, error } = await supabase
    .from('control_folio')
    .select('*')
    .eq('año', año_consulta)
    .single();

    if (error) throw error;

    const folio = `DAIR-${String(data.ultimo_numero).padStart(3, '0')}-${año_consulta}`;

    return {
    folio: folio,
    numero: data.ultimo_numero,
    año: data.año
    };

} catch (err) {
    return {
    error: err.message
    };
}
}


static async obtenerHistorial(año = null) {
try {
    let query = supabase
    .from('control_folio')
    .select('*')
    .order('año', { ascending: false });

    if (año) {
    query = query.eq('año', año);
    }

    const { data, error } = await query;

    if (error) throw error;

    return data.map(reg => ({
    año: reg.año,
    ultimo_numero: reg.ultimo_numero,
    fecha_actualizacion: reg.fecha_actualizacion
    }));

} catch (err) {
    return {
    error: err.message
    };
}
}
}

module.exports = Foliado;