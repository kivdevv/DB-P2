-- Sistema de Gestion Legislativa AIR - TEC
-- Bases de Datos II, 2025
-- Script unico acumulativo, organizado por secciones modulares


-- Issue #0
-- Crear tabla de usuarios
CREATE TABLE IF NOT EXISTS usuario (
    id_usuario UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    correo VARCHAR(100) NOT NULL UNIQUE,
    contraseña_hash VARCHAR(255) NOT NULL,
    nombre_completo VARCHAR(150) NOT NULL,
    rol VARCHAR(50) NOT NULL CHECK (rol IN ('Admin', 'Editor', 'Consulta')),
    estado VARCHAR(20) NOT NULL DEFAULT 'Activo' CHECK (estado IN ('Activo', 'Inactivo')),
    fecha_creacion TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    fecha_actualizacion TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    CONSTRAINT uk_usuario_correo UNIQUE(correo)
);

-- Crear tabla de permisos (relación M:M)
CREATE TABLE IF NOT EXISTS permiso (
    id_permiso SERIAL PRIMARY KEY,
    codigo_accion VARCHAR(50) NOT NULL UNIQUE,
    descripcion TEXT,
    CONSTRAINT uk_permiso_codigo UNIQUE(codigo_accion)
);

-- Tabla de relación usuario-permisos
CREATE TABLE IF NOT EXISTS usuario_permisos (
    id_usuario_permiso SERIAL PRIMARY KEY,
    id_usuario UUID NOT NULL REFERENCES usuario(id_usuario) ON DELETE CASCADE,
    id_permiso INTEGER NOT NULL REFERENCES permiso(id_permiso) ON DELETE CASCADE,
    fecha_asignacion TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    fecha_fin DATE,
    CONSTRAINT uk_usuario_permiso UNIQUE(id_usuario, id_permiso)
);

-- Crear índices para búsquedas rápidas
CREATE INDEX idx_usuario_correo ON usuario(correo);
CREATE INDEX idx_usuario_rol ON usuario(rol);
CREATE INDEX idx_usuario_permisos ON usuario_permisos(id_usuario);

-- Insertar permisos base
INSERT INTO permiso (codigo_accion, descripcion) VALUES
    ('CREAR_ASAMBLEISTA', 'Crear nuevos asambleístas'),
    ('EDITAR_ASAMBLEISTA', 'Editar información de asambleístas'),
    ('CREAR_NORMATIVA', 'Crear reglamentos'),
    ('EDITAR_NORMATIVA', 'Editar reglamentos'),
    ('REGISTRAR_VOTO', 'Registrar votos en sesiones'),
    ('EMITIR_CERTIFICACION', 'Emitir certificaciones'),
    ('VER_AUDITORIA', 'Ver registros de auditoría'),
    ('ADMINISTRAR_USUARIOS', 'Crear y gestionar usuarios')
ON CONFLICT DO NOTHING;


-- SECCION: CATALOGOS TRANSVERSALES

CREATE TABLE catalogo_maestro (
    id_item          SERIAL PRIMARY KEY,
    grupo_catalogo   VARCHAR(50)  NOT NULL,
    nombre           VARCHAR(100) NOT NULL,
    activo           BOOLEAN      NOT NULL DEFAULT TRUE,
    UNIQUE (grupo_catalogo, nombre)
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


-- SECCION: TRIGGERS

CREATE OR REPLACE FUNCTION fn_vigencia_normativa()
RETURNS TRIGGER LANGUAGE plpgsql AS $$
DECLARE
    v_id_historico INT;
BEGIN
    -- Buscar el id_item correspondiente a 'Historico' dentro del grupo ESTADO_VIGENCIA
    SELECT id_item INTO v_id_historico
    FROM catalogo_maestro
    WHERE grupo_catalogo = 'ESTADO_VIGENCIA'
      AND nombre = 'Historico'
    LIMIT 1;

    -- Si ya existe una version vigente del mismo elemento bajo el mismo padre
    -- dentro del mismo reglamento, cerrarla antes de insertar la nueva.
    -- IS NOT DISTINCT FROM trata NULL como igual a NULL (elementos raiz sin padre).
    UPDATE elemento_normativo
    SET fecha_fin_vigencia  = CURRENT_DATE,
        id_estado_vigencia  = v_id_historico
    WHERE id_reglamento     = NEW.id_reglamento
      AND id_elemento_padre IS NOT DISTINCT FROM NEW.id_elemento_padre
      AND numero_etiqueta   = NEW.numero_etiqueta
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
