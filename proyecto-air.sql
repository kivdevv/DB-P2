-- =====================================
-- PROYECTO AIR - Sistema de Gestión Legislativa
-- Base de Datos II, TEC 2025
-- =====================================


-- =====================================
-- SECCION 1: CATALOGOS (Lookup Tables)
-- =====================================

CREATE TABLE catalogo_maestro (
  id_item SERIAL PRIMARY KEY,
  grupo_catalogo VARCHAR(50) NOT NULL,
  nombre VARCHAR(100) NOT NULL,
  activo BOOLEAN NOT NULL DEFAULT TRUE,
  fecha_creacion TIMESTAMP NOT NULL DEFAULT NOW(),
  UNIQUE (grupo_catalogo, nombre)
);

-- Índice para búsquedas rápidas por grupo
CREATE INDEX idx_catalogo_maestro_grupo ON catalogo_maestro(grupo_catalogo);


-- =====================================
-- SECCION 2: SISTEMA / RBAC
-- =====================================

-- (por definir)


-- =====================================
-- SECCION 3: MODULO 1 - IDENTIDAD
-- =====================================

-- =====================================
-- ISSUE #9 - ASAMBLEISTAS
-- DIANA SOLANO / NANA1822

CREATE TABLE asambleista (
  id_asambleista SERIAL PRIMARY KEY,
  nombre_completo VARCHAR(150) NOT NULL,
  cedula VARCHAR(20) UNIQUE NOT NULL,
  correo VARCHAR(150) NOT NULL,
  foto_url TEXT,
  activo BOOLEAN NOT NULL DEFAULT TRUE,
  fecha_registro TIMESTAMP NOT NULL DEFAULT NOW(),
  CONSTRAINT cedula_format CHECK (cedula ~ '^\d-\d{4}-\d{4}$')
);

CREATE TABLE nombramiento (
  id_nombramiento SERIAL PRIMARY KEY,
  id_asambleista INT NOT NULL REFERENCES asambleista(id_asambleista) ON DELETE CASCADE,
  id_sector INT NOT NULL REFERENCES catalogo_maestro(id_item),
  fecha_inicio DATE NOT NULL,
  fecha_fin DATE,
  activo BOOLEAN NOT NULL DEFAULT TRUE,
  CONSTRAINT fecha_orden CHECK (fecha_fin IS NULL OR fecha_fin >= fecha_inicio)
);

CREATE TABLE bitacora_asambleista (
  id_bitacora SERIAL PRIMARY KEY,
  id_asambleista INTEGER REFERENCES asambleista(id_asambleista) ON DELETE CASCADE,
  accion VARCHAR(50) NOT NULL,
  descripcion TEXT,
  fecha TIMESTAMP NOT NULL DEFAULT NOW()
);


-- =====================================
-- SECCION 4: MODULO 2 - NORMATIVA
-- =====================================

-- (por definir en futuros issues)


-- =====================================
-- SECCION 5: MODULO 3 - SESIONES
-- =====================================

-- (por definir en futuros issues)


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

-- Trigger para evitar traslape de nombramientos activos para el mismo sector
CREATE OR REPLACE FUNCTION verificar_traslape_nombramientos()
RETURNS TRIGGER AS $$
BEGIN
  IF NEW.activo = TRUE THEN
    -- Verificar si ya existe un nombramiento activo para el mismo asambleista y sector en las mismas fechas
    IF EXISTS (
      SELECT 1 FROM nombramiento
      WHERE id_asambleista = NEW.id_asambleista
        AND id_sector = NEW.id_sector
        AND activo = TRUE
        AND id_nombramiento != NEW.id_nombramiento
        AND fecha_inicio <= COALESCE(NEW.fecha_fin, CURRENT_DATE)
        AND COALESCE(fecha_fin, CURRENT_DATE) >= NEW.fecha_inicio
    ) THEN
      RAISE EXCEPTION 'No puede haber traslape de nombramientos activos para el mismo asambleista y sector';
    END IF;
  END IF;
  RETURN NEW;
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER trigger_traslape_nombramientos
BEFORE INSERT OR UPDATE ON nombramiento
FOR EACH ROW
EXECUTE FUNCTION verificar_traslape_nombramientos();

-- Trigger para registrar cambios en bitácora de asambleista
CREATE OR REPLACE FUNCTION registrar_cambio_asambleista()
RETURNS TRIGGER AS $$
BEGIN
  IF TG_OP = 'INSERT' THEN
    INSERT INTO bitacora_asambleista (id_asambleista, accion, descripcion)
    VALUES (NEW.id_asambleista, 'CREACION', 'Asambleista registrado');
  ELSIF TG_OP = 'UPDATE' THEN
    INSERT INTO bitacora_asambleista (id_asambleista, accion, descripcion)
    VALUES (NEW.id_asambleista, 'MODIFICACION', 'Datos actualizados');
  END IF;
  RETURN NEW;
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER trigger_bitacora_asambleista
AFTER INSERT OR UPDATE ON asambleista
FOR EACH ROW
EXECUTE FUNCTION registrar_cambio_asambleista();


-- =====================================
-- SECCION 9: FUNCIONES
-- =====================================

-- Función para obtener sector actual de un asambleista
CREATE OR REPLACE FUNCTION obtener_sector_actual(p_id_asambleista INT)
RETURNS VARCHAR AS $$
DECLARE
  v_nombre_sector VARCHAR;
BEGIN
  SELECT cm.nombre INTO v_nombre_sector
  FROM nombramiento n
  JOIN catalogo_maestro cm ON n.id_sector = cm.id_item
  WHERE n.id_asambleista = p_id_asambleista
    AND n.activo = TRUE
    AND n.fecha_inicio <= CURRENT_DATE
    AND (n.fecha_fin IS NULL OR n.fecha_fin >= CURRENT_DATE)
  ORDER BY n.fecha_inicio DESC
  LIMIT 1;
  
  RETURN v_nombre_sector;
END;
$$ LANGUAGE plpgsql;


-- =====================================
-- SECCION 10: DATOS SEMILLA
-- =====================================

-- Datos semilla para sectores de asambleístas (Grupo: SECTOR_ASAMBLEA)
INSERT INTO catalogo_maestro (grupo_catalogo, nombre) VALUES
    ('SECTOR_ASAMBLEA', 'Docente'),
    ('SECTOR_ASAMBLEA', 'Administrativo'),
    ('SECTOR_ASAMBLEA', 'Estudiantil');

-- Datos semilla para niveles de la estructura normativa (para Issue #10)
-- NOTA: Estos se insertarán cuando se integre la rama issue-10
-- INSERT INTO catalogo_maestro (grupo_catalogo, nombre) VALUES
--     ('NIVEL_REGLAMENTO', 'Titulo'),
--     ('NIVEL_REGLAMENTO', 'Capitulo'),
--     ('NIVEL_REGLAMENTO', 'Articulo'),
--     ('NIVEL_REGLAMENTO', 'Inciso'),
--     ('NIVEL_REGLAMENTO', 'Sub-inciso');

-- Estados de vigencia para normativa (para Issue #10)
-- NOTA: Estos se insertarán cuando se integre la rama issue-10
-- INSERT INTO catalogo_maestro (grupo_catalogo, nombre) VALUES
--     ('ESTADO_VIGENCIA', 'Vigente'),
--     ('ESTADO_VIGENCIA', 'Historico'),
--     ('ESTADO_VIGENCIA', 'Derogado');
