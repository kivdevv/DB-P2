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

CREATE TABLE catalogo_sector (

id_sector SERIAL PRIMARY KEY,

nombre VARCHAR(100) NOT NULL,

estado BOOLEAN DEFAULT TRUE

);

CREATE TABLE catalogo_puestos (

id_puesto SERIAL PRIMARY KEY,

nombre VARCHAR(100) NOT NULL,

estado BOOLEAN DEFAULT TRUE

);

CREATE TABLE catalogo_tipo_sesion (

id_tipo_sesion SERIAL PRIMARY KEY,

nombre VARCHAR(50) NOT NULL

);

CREATE TABLE catalogo_tipo_modalidad (

id_modalidad SERIAL PRIMARY KEY,

nombre VARCHAR(50) NOT NULL

);

CREATE TABLE asambleista (

id_asambleista SERIAL PRIMARY KEY,

nombre VARCHAR(150) NOT NULL,

cedula VARCHAR(20) UNIQUE NOT NULL,

correo VARCHAR(150) NOT NULL,

id_sector INTEGER REFERENCES catalogo_sector(id_sector),

fecha_inicio DATE NOT NULL,

fecha_fin DATE,

estado BOOLEAN DEFAULT TRUE,

created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP

);

CREATE TABLE bitacora_asambleistas (

id_bitacora SERIAL PRIMARY KEY,

id_asambleista INTEGER REFERENCES asambleista(id_asambleista),

accion VARCHAR(50),

descripcion TEXT,

fecha TIMESTAMP DEFAULT CURRENT_TIMESTAMP

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

INSERT INTO catalogo_sector(nombre)

VALUES
('Docente'),
('Administrativo'),
('Estudiantil');
