const supabase = require('../config/db');
const Foliado = require('./Foliado');
const crypto = require('crypto');

class Certificado {


static async emitirCertificacion(datos) {
try {
    const {
    id_asambleista,
    tipo_certificacion,
    contenido,
    usuario_secretaria
    } = datos;

    const resultado_folio = await Foliado.generarFolioUnico();
    if (!resultado_folio.exito) {
    throw new Error('Error generando folio: ' + resultado_folio.error);
    }

    const folio_unico = resultado_folio.folio;

    const hash_seguridad = crypto
    .createHash('sha256')
    .update(contenido + folio_unico + Date.now())
    .digest('hex');

    const { data, error } = await supabase
    .from('certificacion_emitida')
    .insert({
        id_asambleista: id_asambleista,
        folio_unico: folio_unico,
        tipo_certificacion: tipo_certificacion,
        contenido: contenido,
        hash_seguridad: hash_seguridad,
        fecha_emision: new Date().toISOString(),
        usuario_secretaria: usuario_secretaria
    })
    .select();

    if (error) throw error;

    return {
    exito: true,
    certificacion: data[0],
    folio: folio_unico,
    hash: hash_seguridad
    };

} catch (err) {
    return {
    exito: false,
    error: err.message
    };
}
}

static async obtenerPorFolio(folio_unico) {
const { data, error } = await supabase
    .from('certificacion_emitida')
    .select('*')
    .eq('folio_unico', folio_unico)
    .single();

if (error) throw new Error('Certificación no encontrada');
return data;
}

static async verificarIntegridad(folio_unico, contenido_verificar) {
try {
    const cert = await this.obtenerPorFolio(folio_unico);

    const hash_recalculado = crypto
    .createHash('sha256')
    .update(contenido_verificar + folio_unico + cert.fecha_emision)
    .digest('hex');

    const es_valida = hash_recalculado === cert.hash_seguridad;

    return {
    folio: folio_unico,
    es_valida: es_valida,
    hash_original: cert.hash_seguridad,
    timestamp: cert.fecha_emision
    };

} catch (err) {
    return {
    error: err.message
    };
}
}

static async listaPorAsambleista(id_asambleista) {
const { data, error } = await supabase
    .from('certificacion_emitida')
    .select('*')
    .eq('id_asambleista', id_asambleista)
    .order('fecha_emision', { ascending: false });

if (error) throw error;
return data;
}
}

module.exports = Certificado;