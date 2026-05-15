-- Sistema de Gestion Legislativa AIR - TEC
-- Bases de Datos II, 2025
-- Script unico acumulativo, organizado por secciones modulares


-- Issue #0

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

-- Tabla: Usuarios del sistema
CREATE TABLE IF NOT EXISTS usuario (
    id_usuario UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    correo VARCHAR(100) NOT NULL UNIQUE,
    contraseña_hash VARCHAR(255) NOT NULL,
    estado VARCHAR(20) NOT NULL DEFAULT 'Activo' CHECK (estado IN ('Activo', 'Inactivo', 'Suspendido')),
    fecha_creacion TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    fecha_actualizacion TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    fecha_ultimo_login TIMESTAMP,
    CONSTRAINT uk_usuario_correo UNIQUE(correo)
);


-- Tabla: Roles institucionales
CREATE TABLE IF NOT EXISTS rol (
    id_rol UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    nombre_rol VARCHAR(50) NOT NULL UNIQUE,
    descripcion TEXT,
    nivel_acceso INT NOT NULL DEFAULT 1 CHECK (nivel_acceso BETWEEN 1 AND 5),
    -- 1=Consulta (lectura), 2=Editor, 3=Admin, 4=Super, 5=Sistema
    activo BOOLEAN DEFAULT TRUE,
    fecha_creacion TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    CONSTRAINT uk_rol_nombre UNIQUE(nombre_rol)
);

-- Tabla: Permisos granulares (recursos + acciones)
CREATE TABLE IF NOT EXISTS permiso (
    id_permiso UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    codigo_accion VARCHAR(100) NOT NULL UNIQUE,
    descripcion TEXT,
    modulo VARCHAR(50) NOT NULL,
    -- Módulos: AUTH, ASAMBLEISTA, NORMATIVA, SESION, CERTIFICACION, AUDITORIA, ADMIN
    recurso VARCHAR(50) NOT NULL,
    accion VARCHAR(20) NOT NULL CHECK (accion IN ('CREAR', 'LEER', 'EDITAR', 'ELIMINAR', 'EJECUTAR')),
    requiere_mfa BOOLEAN DEFAULT FALSE,
    fecha_creacion TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    CONSTRAINT uk_permiso_codigo UNIQUE(codigo_accion)
);

-- Tabla: Relación Usuario-Rol (Un usuario puede tener múltiples roles)
CREATE TABLE IF NOT EXISTS usuario_rol (
    id_usuario_rol UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    id_usuario UUID NOT NULL REFERENCES usuario(id_usuario) ON DELETE CASCADE,
    id_rol UUID NOT NULL REFERENCES rol(id_rol) ON DELETE RESTRICT,
    fecha_asignacion TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    fecha_fin DATE,
    asignado_por UUID REFERENCES usuario(id_usuario),
    razon_asignacion TEXT,
    CONSTRAINT uk_usuario_rol UNIQUE(id_usuario, id_rol),
    CONSTRAINT ck_fecha_fin CHECK (fecha_fin IS NULL OR fecha_fin >= CURRENT_DATE)
);

-- Tabla: Relación Rol-Permiso (Un rol puede tener múltiples permisos)
CREATE TABLE IF NOT EXISTS rol_permiso (
    id_rol_permiso UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    id_rol UUID NOT NULL REFERENCES rol(id_rol) ON DELETE CASCADE,
    id_permiso UUID NOT NULL REFERENCES permiso(id_permiso) ON DELETE CASCADE,
    fecha_asignacion TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    otorgado_por UUID REFERENCES usuario(id_usuario),
    CONSTRAINT uk_rol_permiso UNIQUE(id_rol, id_permiso)
);

-- Tabla: Log de auditoría (Trazabilidad total)
CREATE TABLE IF NOT EXISTS audit_log (
    id_audit_log UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    id_usuario UUID REFERENCES usuario(id_usuario) ON DELETE SET NULL,
    tabla_afectada VARCHAR(100) NOT NULL,
    operacion VARCHAR(10) NOT NULL CHECK (operacion IN ('INSERT', 'UPDATE', 'DELETE')),
    registro_id VARCHAR(100),
    datos_anteriores JSONB,
    datos_nuevos JSONB,
    cambios_detalle TEXT,
    ip_origen INET,
    user_agent TEXT,
    timestamp TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    estado_transaccion VARCHAR(20) DEFAULT 'COMPLETADA'
);

-- Tabla: Sesiones de usuario (Para tracking de logins)
CREATE TABLE IF NOT EXISTS sesion_usuario (
    id_sesion UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    id_usuario UUID NOT NULL REFERENCES usuario(id_usuario) ON DELETE CASCADE,
    token_jwt VARCHAR(500),
    ip_origen INET,
    user_agent TEXT,
    fecha_inicio TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    fecha_fin TIMESTAMP,
    activa BOOLEAN DEFAULT TRUE
);

-- Tabla: Intentos de login fallidos (Prevención de fuerza bruta)
CREATE TABLE IF NOT EXISTS intento_login_fallido (
    id_intento UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    correo VARCHAR(100) NOT NULL,
    ip_origen INET NOT NULL,
    timestamp TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    razon VARCHAR(100)
);

CREATE INDEX idx_usuario_correo ON usuario(correo);
CREATE INDEX idx_usuario_estado ON usuario(estado);
CREATE INDEX idx_usuario_rol_usuario ON usuario_rol(id_usuario);
CREATE INDEX idx_usuario_rol_rol ON usuario_rol(id_rol);
CREATE INDEX idx_rol_permiso_rol ON rol_permiso(id_rol);
CREATE INDEX idx_rol_permiso_permiso ON rol_permiso(id_permiso);
CREATE INDEX idx_audit_log_usuario ON audit_log(id_usuario);
CREATE INDEX idx_audit_log_tabla ON audit_log(tabla_afectada);
CREATE INDEX idx_audit_log_timestamp ON audit_log(timestamp);
CREATE INDEX idx_audit_log_operacion ON audit_log(operacion);
CREATE INDEX idx_sesion_usuario ON sesion_usuario(id_usuario);
CREATE INDEX idx_sesion_activa ON sesion_usuario(activa);
CREATE INDEX idx_intento_login_ip ON intento_login_fallido(ip_origen);

INSERT INTO rol (nombre_rol, descripcion, nivel_acceso) VALUES
    ('Admin', 'Control total del sistema y gestión de usuarios', 3),
    ('Editor', 'Registro de asambleístas, normativa, sesiones, votación', 2),
    ('Consulta', 'Acceso solo lectura: reglamentos y búsqueda de asambleístas', 1)
ON CONFLICT DO NOTHING;

INSERT INTO permiso (codigo_accion, descripcion, modulo, recurso, accion) VALUES
    -- MÓDULO: AUTENTICACIÓN
    ('AUTH_LOGIN', 'Iniciar sesión en el sistema', 'AUTH', 'LOGIN', 'EJECUTAR'),
    ('AUTH_LOGOUT', 'Cerrar sesión', 'AUTH', 'SESION', 'EJECUTAR'),
    ('AUTH_CAMBIAR_CONTRASEÑA', 'Cambiar contraseña propia', 'AUTH', 'CONTRASEÑA', 'EDITAR'),
    
    -- MÓDULO: ASAMBLEISTAS
    ('ASAMBLEISTA_CREAR', 'Crear nuevo asambleísta', 'ASAMBLEISTA', 'ASAMBLEISTA', 'CREAR'),
    ('ASAMBLEISTA_LEER', 'Ver asambleístas', 'ASAMBLEISTA', 'ASAMBLEISTA', 'LEER'),
    ('ASAMBLEISTA_EDITAR', 'Editar información de asambleísta', 'ASAMBLEISTA', 'ASAMBLEISTA', 'EDITAR'),
    ('ASAMBLEISTA_ELIMINAR', 'Eliminar asambleísta', 'ASAMBLEISTA', 'ASAMBLEISTA', 'ELIMINAR'),
    ('NOMBRAMIENTO_CREAR', 'Crear nombramiento (sector + período)', 'ASAMBLEISTA', 'NOMBRAMIENTO', 'CREAR'),
    ('NOMBRAMIENTO_EDITAR', 'Editar nombramiento', 'ASAMBLEISTA', 'NOMBRAMIENTO', 'EDITAR'),
    
    -- MÓDULO: NORMATIVA
    ('NORMATIVA_CREAR', 'Crear reglamento', 'NORMATIVA', 'REGLAMENTO', 'CREAR'),
    ('NORMATIVA_EDITAR', 'Editar reglamento o artículos', 'NORMATIVA', 'REGLAMENTO', 'EDITAR'),
    ('NORMATIVA_LEER', 'Ver reglamentos vigentes', 'NORMATIVA', 'REGLAMENTO', 'LEER'),
    ('NORMATIVA_COMPILAR', 'Ver compilador de normativa', 'NORMATIVA', 'COMPILADOR', 'EJECUTAR'),
    
    -- MÓDULO: SESIONES Y VOTACIÓN
    ('SESION_CREAR', 'Crear sesión plenaria', 'SESION', 'SESION', 'CREAR'),
    ('SESION_REGISTRAR_ASISTENCIA', 'Registrar asistencia de asambleístas', 'SESION', 'ASISTENCIA', 'CREAR'),
    ('VOTO_REGISTRAR', 'Registrar voto en sesión', 'SESION', 'VOTO', 'CREAR'),
    ('SESION_LEER', 'Ver sesiones y resultados', 'SESION', 'SESION', 'LEER'),
    
    -- MÓDULO: CERTIFICACIONES
    ('CERTIFICACION_EMITIR', 'Emitir atestado/certificación', 'CERTIFICACION', 'CERTIFICACION', 'CREAR'),
    ('CERTIFICACION_LEER', 'Ver certificaciones emitidas', 'CERTIFICACION', 'CERTIFICACION', 'LEER'),
    
    -- MÓDULO: AUDITORÍA
    ('AUDITORIA_LEER', 'Ver logs de auditoría', 'AUDITORIA', 'AUDITORIA', 'LEER'),
    
    -- MÓDULO: ADMINISTRACIÓN
    ('ADMIN_USUARIO_CREAR', 'Crear usuarios', 'ADMIN', 'USUARIO', 'CREAR'),
    ('ADMIN_USUARIO_EDITAR', 'Editar usuarios', 'ADMIN', 'USUARIO', 'EDITAR'),
    ('ADMIN_USUARIO_ELIMINAR', 'Eliminar usuarios', 'ADMIN', 'USUARIO', 'ELIMINAR'),
    ('ADMIN_ROL_ASIGNAR', 'Asignar roles a usuarios', 'ADMIN', 'ROL', 'EDITAR'),
    ('ADMIN_PERMISO_ASIGNAR', 'Asignar permisos a roles', 'ADMIN', 'PERMISO', 'EDITAR'),
    ('ADMIN_CONFIG', 'Acceder a configuración del sistema', 'ADMIN', 'CONFIG', 'EDITAR')
ON CONFLICT DO NOTHING;

DO $$
DECLARE
    v_rol_admin UUID;
    v_rol_editor UUID;
    v_rol_consulta UUID;
BEGIN
    SELECT id_rol INTO v_rol_admin FROM rol WHERE nombre_rol = 'Admin';
    SELECT id_rol INTO v_rol_editor FROM rol WHERE nombre_rol = 'Editor';
    SELECT id_rol INTO v_rol_consulta FROM rol WHERE nombre_rol = 'Consulta';

    -- ROL ADMIN: Todos los permisos
    INSERT INTO rol_permiso (id_rol, id_permiso)
    SELECT v_rol_admin, id_permiso FROM permiso
    ON CONFLICT DO NOTHING;

    -- ROL EDITOR: Permisos operacionales (menos administración)
    INSERT INTO rol_permiso (id_rol, id_permiso)
    SELECT v_rol_editor, id_permiso FROM permiso
    WHERE codigo_accion IN (
        'AUTH_LOGIN', 'AUTH_LOGOUT',
        'ASAMBLEISTA_CREAR', 'ASAMBLEISTA_LEER', 'ASAMBLEISTA_EDITAR',
        'NOMBRAMIENTO_CREAR', 'NOMBRAMIENTO_EDITAR',
        'NORMATIVA_CREAR', 'NORMATIVA_EDITAR', 'NORMATIVA_LEER', 'NORMATIVA_COMPILAR',
        'SESION_CREAR', 'SESION_REGISTRAR_ASISTENCIA', 'VOTO_REGISTRAR', 'SESION_LEER',
        'CERTIFICACION_EMITIR', 'CERTIFICACION_LEER'
    )
    ON CONFLICT DO NOTHING;

    -- ROL CONSULTA: Solo lectura
    INSERT INTO rol_permiso (id_rol, id_permiso)
    SELECT v_rol_consulta, id_permiso FROM permiso
    WHERE codigo_accion IN (
        'AUTH_LOGIN', 'AUTH_LOGOUT',
        'ASAMBLEISTA_LEER',
        'NORMATIVA_LEER', 'NORMATIVA_COMPILAR',
        'SESION_LEER'
    )
    ON CONFLICT DO NOTHING;
END;
$$;

CREATE OR REPLACE FUNCTION fn_registrar_auditoria()
RETURNS TRIGGER AS $$
DECLARE
    v_usuario_id UUID;
    v_ip INET;
    v_usuario_agent TEXT;
    v_cambios TEXT;
BEGIN
    -- Obtener usuario actual desde sesión
    BEGIN
        v_usuario_id := current_setting('app.usuario_id')::UUID;
    EXCEPTION WHEN OTHERS THEN
        v_usuario_id := NULL;
    END;
    
    -- Obtener IP del cliente
    v_ip := inet_client_addr();
    v_usuario_agent := current_setting('app.user_agent', true);
    
    -- Calcular qué cambió (solo para UPDATE)
    IF TG_OP = 'UPDATE' THEN
        v_cambios := 'Campos modificados: ' || 
            string_agg(
                key || ' (de: ' || OLD_values->key || ' a: ' || NEW_values->key || ')',
                ', '
            )
        FROM (
            SELECT key FROM jsonb_each(to_jsonb(NEW))
            WHERE to_jsonb(NEW)->key != to_jsonb(OLD)->key
        ) AS changed_fields(key);
    END IF;
    
    -- Registrar en audit_log
    INSERT INTO audit_log (
        id_usuario,
        tabla_afectada,
        operacion,
        registro_id,
        datos_anteriores,
        datos_nuevos,
        cambios_detalle,
        ip_origen,
        user_agent
    ) VALUES (
        v_usuario_id,
        TG_TABLE_NAME,
        TG_OP,
        -- Corrección: Usar to_jsonb() y manejar el caso de DELETE
        COALESCE(
            (to_jsonb(CASE WHEN TG_OP = 'DELETE' THEN OLD ELSE NEW END) ->> 'id_usuario'),
            (to_jsonb(CASE WHEN TG_OP = 'DELETE' THEN OLD ELSE NEW END) ->> 'id_asambleista'),
            (to_jsonb(CASE WHEN TG_OP = 'DELETE' THEN OLD ELSE NEW END) ->> 'id_resolucion'),
            (to_jsonb(CASE WHEN TG_OP = 'DELETE' THEN OLD ELSE NEW END) ->> 'id_nombramiento'),
            'desconocido'
        ),
        CASE WHEN TG_OP = 'DELETE' OR TG_OP = 'UPDATE' THEN row_to_json(OLD) ELSE NULL END,
        CASE WHEN TG_OP = 'INSERT' OR TG_OP = 'UPDATE' THEN row_to_json(NEW) ELSE NULL END,
        v_cambios,
        v_ip,
        v_usuario_agent
    );
    
    IF TG_OP = 'DELETE' THEN
        RETURN OLD;
    ELSE
        RETURN NEW;
    END IF;
END;
$$ LANGUAGE plpgsql;

-- Activar trigger en tablas sensibles
CREATE TRIGGER tg_auditoria_usuario
    AFTER INSERT OR UPDATE OR DELETE ON usuario
    FOR EACH ROW
    EXECUTE FUNCTION fn_registrar_auditoria();

CREATE TRIGGER tg_auditoria_usuario_rol
    AFTER INSERT OR UPDATE OR DELETE ON usuario_rol
    FOR EACH ROW
    EXECUTE FUNCTION fn_registrar_auditoria();

-- SECCION: CATALOGOS TRANSVERSALES

-- =====================================
-- ISSUE #9 - ASAMBLEISTAS
-- DIANA SOLANO / NANA1822

CREATE TABLE asambleista (
  id_asambleista SERIAL PRIMARY KEY,
  id_usuario UUID REFERENCES usuario(id_usuario),
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

    id_asambleista INT NOT NULL,

    CONSTRAINT fk_proponente_propuesta
        FOREIGN KEY (id_propuesta)
        REFERENCES propuesta(id_propuesta),

    -- FK de usuario pendiente hasta integrar modulo identidad
);

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

    id_asambleista INT NOT NULL,

    id_estado_asistencia INT NOT NULL,

    CONSTRAINT fk_asistencia_sesion
        FOREIGN KEY (id_sesion)
        REFERENCES sesiones(id_sesion),

    CONSTRAINT fk_estado_asistencia
        FOREIGN KEY (id_estado_asistencia)
        REFERENCES catalogo_asistencia_sesion_comision(id_estado_asistencia),

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
    id_asambleista,
    id_estado_asistencia
)
VALUES (
    1,
    1,
    1
);

INSERT INTO proponente_propuesta (
    id_propuesta,
    id_asambleista
)
VALUES (
    1,
    1
);

