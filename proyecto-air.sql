-- =====================================
-- PROYECTO AIR - Sistema de Gestión Legislativa
-- Base de Datos II, TEC 2025
-- =====================================


-- =====================================
-- SECCION 1: CATALOGOS (Lookup Tables)
-- =====================================

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

-- =====================================
-- SECCION 2: SISTEMA / RBAC
-- =====================================

-- (por definir)


-- =====================================
-- SECCION 3: MODULO 1 - IDENTIDAD
-- =====================================

-- (por definir)


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

-- =====================================
-- SECCION 5: MODULO 3 - SESIONES
-- =====================================

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


-- =====================================
-- SECCION 6: MODULO 4 - COMISIONES
-- =====================================

-- (por definir)


-- =====================================
-- SECCION 7: MODULO 5 - CERTIFICACIONES
-- =====================================

-- (por definir)


-- =====================================
-- SECCION 8: TRIGGERS
-- =====================================

-- (por definir)


-- =====================================
-- SECCION 9: FUNCIONES
-- =====================================

-- (por definir)


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