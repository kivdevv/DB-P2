const Normativa = require('../models/Normativa');

async function listarReglamentos() {
    return Normativa.listarReglamentos();
}

async function obtenerReglamento(idReglamento) {
    const reglamento = await Normativa.obtenerReglamento(idReglamento);
    if (!reglamento) throw new Error('Reglamento no encontrado');
    return reglamento;
}

async function obtenerArbolReglamento(idReglamento) {
    const reglamento = await obtenerReglamento(idReglamento);
    const elementos = await Normativa.listarElementosVigentesPorReglamento(idReglamento);

    // Primera pasada: construir mapa id -> nodo para acceso O(1) en la segunda pasada.
    // Segunda pasada: enlazar cada nodo a su padre o a raices sin recorrer el array entero por cada elemento.
    const mapa = {};
    for (const el of elementos) {
        mapa[el.id_elemento] = {
            id_elemento:          el.id_elemento,
            id_elemento_padre:    el.id_elemento_padre,
            numero_etiqueta:      el.numero_etiqueta,
            contenido_texto:      el.contenido_texto,
            orden:                el.orden,
            fecha_inicio_vigencia: el.fecha_inicio_vigencia,
            nivel:                el.nivel?.nombre ?? null,
            estado:               el.estado?.nombre ?? null,
            hijos:                [],
        };
    }

    const raices = [];
    for (const el of elementos) {
        const nodo = mapa[el.id_elemento];
        if (el.id_elemento_padre !== null && mapa[el.id_elemento_padre]) {
            mapa[el.id_elemento_padre].hijos.push(nodo);
        } else {
            raices.push(nodo);
        }
    }

    function ordenarHijos(nodo) {
        nodo.hijos.sort((a, b) => a.orden - b.orden);
        nodo.hijos.forEach(ordenarHijos);
    }
    raices.sort((a, b) => a.orden - b.orden);
    raices.forEach(ordenarHijos);

    return {
        reglamento: {
            id_reglamento:   reglamento.id_reglamento,
            nombre_normativa: reglamento.nombre_normativa,
            sigla:           reglamento.sigla,
            emisor:          reglamento.emisor,
        },
        raices,
    };
}

async function obtenerElementoConTrazabilidad(idElemento) {
    const elemento = await Normativa.obtenerElementoPorId(idElemento);
    if (!elemento) throw new Error('Elemento no encontrado');

    const versiones = await Normativa.listarVersionesDeElemento(
        elemento.id_reglamento,
        elemento.id_elemento_padre,
        elemento.numero_etiqueta
    );

    return {
        actual: {
            ...elemento,
            nivel:  elemento.nivel?.nombre  ?? null,
            estado: elemento.estado?.nombre ?? null,
        },
        versiones,
    };
}

module.exports = {
    listarReglamentos,
    obtenerReglamento,
    obtenerArbolReglamento,
    obtenerElementoConTrazabilidad,
};
