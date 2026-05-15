const supabase = require('../config/db');

async function obtenerCatalogo(grupoCatalogo) {

    const { data, error } = await supabase
        .from('catalogo_maestro')
        .select(`
            id_item,
            grupo_catalogo,
            nombre
        `)
        .eq('grupo_catalogo', grupoCatalogo)
        .order('nombre');

    if (error) throw error;

    return data;
}

module.exports = {
    obtenerCatalogo
};