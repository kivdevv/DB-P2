-- =====================================
-- PROYECTO AIR - Sistema de Gestión Legislativa
-- Base de Datos II, TEC 2025
-- =====================================


-- =====================================
-- SECCION 1: CATALOGOS (Lookup Tables)
-- =====================================

-- (por definir)


-- =====================================
-- SECCION 2: SISTEMA / RBAC
-- =====================================

-- (por definir)


-- =====================================
-- SECCION 3: MODULO 1 - IDENTIDAD
-- =====================================

-- =====================================
-- ISSUE #9 - ASAMBLEISTAS
-- DIANA SOLANO

CREATE TABLE asambleista (

id_asambleista SERIAL PRIMARY KEY,

nombre_completo VARCHAR(150) NOT NULL,

cedula VARCHAR(20) UNIQUE NOT NULL,

correo VARCHAR(150) NOT NULL,

foto_url TEXT,

activo BOOLEAN NOT NULL DEFAULT TRUE,

fecha_registro TIMESTAMP NOT NULL DEFAULT NOW()

);

CREATE TABLE nombramiento (

id_nombramiento SERIAL PRIMARY KEY,

id_asambleista INT NOT NULL REFERENCES asambleista(id_asambleista),

id_sector INT NOT NULL REFERENCES catalogo_maestro(id_item),

fecha_inicio DATE NOT NULL,

fecha_fin DATE,

activo BOOLEAN NOT NULL DEFAULT TRUE

);

CREATE TABLE bitacora_asambleista (

id_bitacora SERIAL PRIMARY KEY,

id_asambleista INTEGER REFERENCES asambleista(id_asambleista),

accion VARCHAR(50) NOT NULL,

descripcion TEXT,

fecha TIMESTAMP NOT NULL DEFAULT NOW()

);


-- =====================================
-- SECCION 4: MODULO 2 - NORMATIVA
-- =====================================

-- (por definir)


-- =====================================
-- SECCION 5: MODULO 3 - SESIONES
-- =====================================

-- (por definir)


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

INSERT INTO catalogo_maestro (grupo_catalogo, nombre) VALUES
    ('SECTOR_ASAMBLEA', 'Docente'),
    ('SECTOR_ASAMBLEA', 'Administrativo'),
    ('SECTOR_ASAMBLEA', 'Estudiantil');
