-- Sistema de Gestion Legislativa AIR - TEC
-- Bases de Datos II, 2025
-- Script unico acumulativo, organizado por secciones modulares


-- SECCION: CATALOGOS TRANSVERSALES

CREATE TABLE catalogo_maestro (
    id_item SERIAL PRIMARY KEY,
    grupo_catalogo VARCHAR(50) NOT NULL,
    nombre VARCHAR(100) NOT NULL,
    activo BOOLEAN NOT NULL DEFAULT TRUE,
    UNIQUE (grupo_catalogo, nombre)
);

CREATE TABLE catalogo_etapas_propuestas (
    id_etapa_propuesta SERIAL PRIMARY KEY,
    nombre VARCHAR(100) UNIQUE NOT NULL
);

CREATE TABLE catalogo_estado_propuestas (
    id_estado_propuesta SERIAL PRIMARY KEY,
    nombre VARCHAR(100) UNIQUE NOT NULL
);

CREATE TABLE catalogo_tipo_mayoria_requerida (
    id_tipo_mayoria_requerida SERIAL PRIMARY KEY,
    nombre VARCHAR(100) UNIQUE NOT NULL
);

CREATE TABLE catalogo_tipo_reforma (
    id_tipo_reforma SERIAL PRIMARY KEY,
    nombre VARCHAR(100) UNIQUE NOT NULL
);

CREATE TABLE catalogo_estado_vigencia (
    id_estado_vigencia SERIAL PRIMARY KEY,
    nombre VARCHAR(100) UNIQUE NOT NULL
);

CREATE TABLE catalogo_asistencia_sesion_comision (
    id_estado_asistencia SERIAL PRIMARY KEY,
    nombre VARCHAR(100) UNIQUE NOT NULL
);

-- SECCION: MODULO IDENTIDAD Y ACTORES (Issue 9, 14)
-- Reservado para Diana / Kevin. No modificar hasta que ellos integren su aporte.


-- SECCION: MODULO JERARQUIA NORMATIVA (Issue 10)

CREATE TABLE reglamento (
    id_reglamento    SERIAL PRIMARY KEY,
    nombre_normativa VARCHAR(200) NOT NULL,
    sigla            VARCHAR(20)  NOT NULL UNIQUE,
    emisor           VARCHAR(10)  NOT NULL CHECK (emisor IN ('AIR', 'CI')),
    fecha_registro   TIMESTAMP    NOT NULL DEFAULT NOW()
);

CREATE TABLE elemento_normativo (
    id_elemento          SERIAL PRIMARY KEY,
    id_reglamento        INT  NOT NULL REFERENCES reglamento (id_reglamento),
    id_elemento_padre    INT           REFERENCES elemento_normativo (id_elemento),
    id_nivel_reglamento  INT  NOT NULL REFERENCES catalogo_maestro (id_item),
    id_estado_vigencia   INT  NOT NULL REFERENCES catalogo_maestro (id_item),
    numero_etiqueta      VARCHAR(20)  NOT NULL,
    contenido_texto      TEXT         NOT NULL,
    orden                INT          NOT NULL,
    fecha_inicio_vigencia DATE        NOT NULL,
    fecha_fin_vigencia    DATE        NULL
);

-- Impide dos versiones activas del mismo elemento bajo el mismo padre dentro del mismo reglamento.
-- NULLS NOT DISTINCT hace que dos filas raiz (id_elemento_padre NULL) se consideren iguales
-- en la evaluacion del indice, cerrando el caso de articulos raiz duplicados.
CREATE UNIQUE INDEX idx_elemento_vigente_unico
    ON elemento_normativo (id_reglamento, id_elemento_padre, numero_etiqueta) NULLS NOT DISTINCT
    WHERE fecha_fin_vigencia IS NULL;


-- SECCION: MODULO SESIONES Y TRAMITE (Issue 15, Sprint 3)
-- Reservado. No modificar hasta Sprint 3.

-- =====================================
-- SECCION 4: MODULO 2 - NORMATIVA
-- =====================================

CREATE TABLE propuesta (
    id_propuesta SERIAL PRIMARY KEY,
    titulo VARCHAR(255) NOT NULL,
    descripcion TEXT NOT NULL,
    fecha_creacion TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    id_etapa_propuesta INT NOT NULL,
    id_estado_propuesta INT NOT NULL,
    id_tipo_mayoria_requerida INT NOT NULL,
    id_tipo_reforma INT NOT NULL,

    CONSTRAINT fk_etapa_propuesta
        FOREIGN KEY (id_etapa_propuesta)
        REFERENCES catalogo_etapas_propuestas(id_etapa_propuesta),

    CONSTRAINT fk_estado_propuesta
        FOREIGN KEY (id_estado_propuesta)
        REFERENCES catalogo_estado_propuestas(id_estado_propuesta),

    CONSTRAINT fk_tipo_mayoria
        FOREIGN KEY (id_tipo_mayoria_requerida)
        REFERENCES catalogo_tipo_mayoria_requerida(id_tipo_mayoria_requerida),

    CONSTRAINT fk_tipo_reforma
        FOREIGN KEY (id_tipo_reforma)
        REFERENCES catalogo_tipo_reforma(id_tipo_reforma)
);

CREATE TABLE bitacora_propuesta (
    id_bitacora_propuesta SERIAL PRIMARY KEY,

    id_propuesta INT NOT NULL,

    fecha_movimiento TIMESTAMP DEFAULT CURRENT_TIMESTAMP,

    detalle TEXT NOT NULL,

    CONSTRAINT fk_bitacora_propuesta
        FOREIGN KEY (id_propuesta)
        REFERENCES propuesta(id_propuesta)
);
CREATE TABLE proponente_propuesta (
    id_proponente_propuesta SERIAL PRIMARY KEY,

    id_propuesta INT NOT NULL,

    id_usuario INT NOT NULL,

    CONSTRAINT fk_proponente_propuesta
        FOREIGN KEY (id_propuesta)
        REFERENCES propuesta(id_propuesta)

    -- FK de usuario pendiente hasta integrar modulo identidad
);

-- SECCION: TRIGGERS

CREATE TABLE sesiones (
    id_sesion SERIAL PRIMARY KEY,

    numero_sesion INT NOT NULL,

    fecha DATE NOT NULL,

    link_acta TEXT,

    quorum_requerido INT NOT NULL
);

CREATE TABLE acta (
    id_acta SERIAL PRIMARY KEY,

    id_sesion INT NOT NULL,

    fecha_aprobacion DATE,

    url_documento TEXT,

    observaciones TEXT,

    CONSTRAINT fk_acta_sesion
        FOREIGN KEY (id_sesion)
        REFERENCES sesiones(id_sesion)
);
CREATE TABLE asistencia_sesion_plenaria (
    id_asistencia SERIAL PRIMARY KEY,

    id_sesion INT NOT NULL,

    id_usuario INT NOT NULL,

    id_estado_asistencia INT NOT NULL,

    CONSTRAINT fk_asistencia_sesion
        FOREIGN KEY (id_sesion)
        REFERENCES sesiones(id_sesion),

    CONSTRAINT fk_estado_asistencia
        FOREIGN KEY (id_estado_asistencia)
        REFERENCES catalogo_asistencia_sesion_comision(id_estado_asistencia)

    -- FK usuario pendiente hasta integrar modulo identidad
);

CREATE OR REPLACE FUNCTION fn_vigencia_normativa()
RETURNS TRIGGER LANGUAGE plpgsql AS $$
DECLARE
    v_id_historico INT;
BEGIN
    SELECT id_item INTO v_id_historico
    FROM catalogo_maestro
    WHERE grupo_catalogo = 'ESTADO_VIGENCIA'
      AND nombre = 'Historico'
    LIMIT 1;

    UPDATE elemento_normativo
    SET fecha_fin_vigencia = CURRENT_DATE,
        id_estado_vigencia = v_id_historico
    WHERE id_reglamento = NEW.id_reglamento
      AND id_elemento_padre IS NOT DISTINCT FROM NEW.id_elemento_padre
      AND numero_etiqueta = NEW.numero_etiqueta
      AND fecha_fin_vigencia IS NULL;

    RETURN NEW;
END;
$$;

CREATE TRIGGER tg_vigencia_normativa
    BEFORE INSERT ON elemento_normativo
    FOR EACH ROW
    EXECUTE FUNCTION fn_vigencia_normativa();

-- Datos semilla

-- Niveles jerarquicos de la estructura normativa
INSERT INTO catalogo_maestro (grupo_catalogo, nombre) VALUES
    ('NIVEL_REGLAMENTO', 'Titulo'),
    ('NIVEL_REGLAMENTO', 'Capitulo'),
    ('NIVEL_REGLAMENTO', 'Articulo'),
    ('NIVEL_REGLAMENTO', 'Inciso'),
    ('NIVEL_REGLAMENTO', 'Sub-inciso');

-- Estados posibles de vigencia de un elemento normativo
INSERT INTO catalogo_maestro (grupo_catalogo, nombre) VALUES
    ('ESTADO_VIGENCIA', 'Vigente'),
    ('ESTADO_VIGENCIA', 'Historico'),
    ('ESTADO_VIGENCIA', 'Derogado');

INSERT INTO reglamento (nombre_normativa, sigla, emisor) VALUES
    ('Estatuto Organico del Instituto Tecnologico de Costa Rica', 'EOITCR', 'AIR');

-- Elementos de demo para el EOITCR.
-- La jerarquia es: Titulo I > Capitulo I > Articulo 1 (Inciso a, Inciso b), Articulo 2
DO $$
DECLARE
    v_reglamento      INT;
    v_nivel_titulo    INT;
    v_nivel_capitulo  INT;
    v_nivel_articulo  INT;
    v_nivel_inciso    INT;
    v_estado_vigente  INT;
    v_id_titulo       INT;
    v_id_capitulo     INT;
    v_id_articulo1    INT;
BEGIN
    SELECT id_reglamento INTO v_reglamento FROM reglamento WHERE sigla = 'EOITCR';

    SELECT id_item INTO v_nivel_titulo   FROM catalogo_maestro WHERE grupo_catalogo = 'NIVEL_REGLAMENTO' AND nombre = 'Titulo';
    SELECT id_item INTO v_nivel_capitulo FROM catalogo_maestro WHERE grupo_catalogo = 'NIVEL_REGLAMENTO' AND nombre = 'Capitulo';
    SELECT id_item INTO v_nivel_articulo FROM catalogo_maestro WHERE grupo_catalogo = 'NIVEL_REGLAMENTO' AND nombre = 'Articulo';
    SELECT id_item INTO v_nivel_inciso   FROM catalogo_maestro WHERE grupo_catalogo = 'NIVEL_REGLAMENTO' AND nombre = 'Inciso';

    SELECT id_item INTO v_estado_vigente FROM catalogo_maestro WHERE grupo_catalogo = 'ESTADO_VIGENCIA' AND nombre = 'Vigente';

    INSERT INTO elemento_normativo
        (id_reglamento, id_elemento_padre, id_nivel_reglamento, id_estado_vigencia,
         numero_etiqueta, contenido_texto, orden, fecha_inicio_vigencia, fecha_fin_vigencia)
    VALUES
        (v_reglamento, NULL, v_nivel_titulo, v_estado_vigente,
         'I', 'De la naturaleza y fines del Instituto', 1, '2020-01-01', NULL)
    RETURNING id_elemento INTO v_id_titulo;

    INSERT INTO elemento_normativo
        (id_reglamento, id_elemento_padre, id_nivel_reglamento, id_estado_vigencia,
         numero_etiqueta, contenido_texto, orden, fecha_inicio_vigencia, fecha_fin_vigencia)
    VALUES
        (v_reglamento, v_id_titulo, v_nivel_capitulo, v_estado_vigente,
         'I', 'Disposiciones generales', 1, '2020-01-01', NULL)
    RETURNING id_elemento INTO v_id_capitulo;

    INSERT INTO elemento_normativo
        (id_reglamento, id_elemento_padre, id_nivel_reglamento, id_estado_vigencia,
         numero_etiqueta, contenido_texto, orden, fecha_inicio_vigencia, fecha_fin_vigencia)
    VALUES
        (v_reglamento, v_id_capitulo, v_nivel_articulo, v_estado_vigente,
         '1', 'El Instituto Tecnologico de Costa Rica es una institucion nacional autonoma de educacion superior universitaria.', 1, '2020-01-01', NULL)
    RETURNING id_elemento INTO v_id_articulo1;

    INSERT INTO elemento_normativo
        (id_reglamento, id_elemento_padre, id_nivel_reglamento, id_estado_vigencia,
         numero_etiqueta, contenido_texto, orden, fecha_inicio_vigencia, fecha_fin_vigencia)
    VALUES
        (v_reglamento, v_id_capitulo, v_nivel_articulo, v_estado_vigente,
         '2', 'El Instituto tendra su sede principal en la ciudad de Cartago.', 2, '2020-01-01', NULL);

    INSERT INTO elemento_normativo
        (id_reglamento, id_elemento_padre, id_nivel_reglamento, id_estado_vigencia,
         numero_etiqueta, contenido_texto, orden, fecha_inicio_vigencia, fecha_fin_vigencia)
    VALUES
        (v_reglamento, v_id_articulo1, v_nivel_inciso, v_estado_vigente,
         'a', 'Formara profesionales en el campo tecnologico que el desarrollo del pais requiera.', 1, '2020-01-01', NULL),
        (v_reglamento, v_id_articulo1, v_nivel_inciso, v_estado_vigente,
         'b', 'Fomentara la investigacion tecnologica y cientifica.', 2, '2020-01-01', NULL);
END;
$$;

-- =====================================
-- SECCION 10: DATOS SEMILLA
-- =====================================

INSERT INTO catalogo_etapas_propuestas (nombre)
VALUES
('Borrador'),
('En revisión'),
('En votación'),
('Aprobada');

INSERT INTO catalogo_estado_propuestas (nombre)
VALUES
('Activa'),
('Archivada'),
('Aprobada'),
('Rechazada');

INSERT INTO catalogo_tipo_mayoria_requerida (nombre)
VALUES
('Mayoría simple'),
('Mayoría calificada');

INSERT INTO catalogo_tipo_reforma (nombre)
VALUES
('Reforma parcial'),
('Reforma total'),
('Derogación');

INSERT INTO catalogo_estado_vigencia (nombre)
VALUES
('Vigente'),
('No vigente');

INSERT INTO catalogo_asistencia_sesion_comision (nombre)
VALUES
('Presente'),
('Ausente'),
('Justificado');

INSERT INTO sesiones (
    numero_sesion,
    fecha,
    link_acta,
    quorum_requerido
)
VALUES (
    101,
    '2025-05-15',
    'https://air.tec.ac.cr/actas/sesion101.pdf',
    50
);

INSERT INTO propuesta (
    titulo,
    descripcion,
    id_etapa_propuesta,
    id_estado_propuesta,
    id_tipo_mayoria_requerida,
    id_tipo_reforma
)
VALUES (
    'Reforma Reglamento General',
    'Actualización de artículos institucionales.',
    1,
    1,
    1,
    1
);
INSERT INTO asistencia_sesion_plenaria (
    id_sesion,
    id_usuario,
    id_estado_asistencia
)
VALUES (
    1,
    1,
    1
);

INSERT INTO proponente_propuesta (
    id_propuesta,
    id_usuario
)
VALUES (
    1,
    1
);
