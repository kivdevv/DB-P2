# Diccionario de Datos - Sistema de Gestión Legislativa AIR

## Descripción General

El sistema AIR (Asamblea Institucional Representativa) administra la gestión legislativa institucional del Instituto Tecnológico de Costa Rica.

Incluye módulos de:

- Gestión de usuarios y autenticación
- Asambleístas y nombramientos
- Normativa institucional
- Propuestas y reformas
- Sesiones plenarias y comisiones
- Auditoría y trazabilidad
- Catálogos transversales

Base de datos implementada en PostgreSQL mediante Supabase. :contentReference[oaicite:0]{index=0}

---

# Tabla: catalogo_maestro

## Descripción

Tabla transversal utilizada para administrar catálogos reutilizables del sistema mediante patrón Lookup Table.

## Catálogos utilizados

- NIVEL_REGLAMENTO
- ESTADO_VIGENCIA
- SECTOR_ASAMBLEA
- SECTOR
- PUESTO
- TIPO_SESION
- TIPO_MODALIDAD

| Campo | Tipo | Restricciones | Descripción |
|---|---|---|---|
| id_item | SERIAL | PK | Identificador del catálogo |
| grupo_catalogo | VARCHAR(50) | NOT NULL | Grupo lógico |
| nombre | VARCHAR(100) | NOT NULL | Valor del catálogo |
| activo | BOOLEAN | DEFAULT TRUE | Estado del registro |
| fecha_creacion | TIMESTAMP | DEFAULT NOW() | Fecha de creación |

## Restricciones

- UNIQUE(grupo_catalogo, nombre)

:contentReference[oaicite:1]{index=1}

---

# Tabla: usuario

## Descripción

Almacena usuarios autenticados del sistema.

| Campo | Tipo | Restricciones |
|---|---|---|
| id_usuario | UUID | PK |
| correo | VARCHAR(100) | UNIQUE, NOT NULL |
| contraseña_hash | VARCHAR(255) | NOT NULL |
| estado | VARCHAR(20) | CHECK |
| fecha_creacion | TIMESTAMP | DEFAULT CURRENT_TIMESTAMP |
| fecha_actualizacion | TIMESTAMP | DEFAULT CURRENT_TIMESTAMP |
| fecha_ultimo_login | TIMESTAMP | NULL |

:contentReference[oaicite:2]{index=2}

---

# Tabla: rol

## Descripción

Define roles institucionales y niveles de acceso.

| Campo | Tipo | Restricciones |
|---|---|---|
| id_rol | UUID | PK |
| nombre_rol | VARCHAR(50) | UNIQUE |
| descripcion | TEXT | NULL |
| nivel_acceso | INT | CHECK BETWEEN 1 AND 5 |
| activo | BOOLEAN | DEFAULT TRUE |
| fecha_creacion | TIMESTAMP | DEFAULT CURRENT_TIMESTAMP |

:contentReference[oaicite:3]{index=3}

---

# Tabla: permiso

## Descripción

Catálogo de permisos granulares del sistema.

| Campo | Tipo |
|---|---|
| id_permiso | UUID |
| codigo_accion | VARCHAR(100) |
| descripcion | TEXT |
| modulo | VARCHAR(50) |
| recurso | VARCHAR(50) |
| accion | VARCHAR(20) |
| requiere_mfa | BOOLEAN |

:contentReference[oaicite:4]{index=4}

---

# Tabla: usuario_rol

## Descripción

Relaciona usuarios con roles institucionales.

| Campo | Tipo |
|---|---|
| id_usuario_rol | UUID |
| id_usuario | UUID |
| id_rol | UUID |
| fecha_asignacion | TIMESTAMP |
| fecha_fin | DATE |

:contentReference[oaicite:5]{index=5}

---

# Tabla: rol_permiso

## Descripción

Relaciona permisos asignados a roles.

| Campo | Tipo |
|---|---|
| id_rol_permiso | UUID |
| id_rol | UUID |
| id_permiso | UUID |
| fecha_asignacion | TIMESTAMP |

:contentReference[oaicite:6]{index=6}

---

# Tabla: audit_log

## Descripción

Bitácora principal de auditoría del sistema.

| Campo | Tipo |
|---|---|
| id_audit_log | UUID |
| id_usuario | UUID |
| tabla_afectada | VARCHAR(100) |
| operacion | VARCHAR(10) |
| registro_id | VARCHAR(100) |
| datos_anteriores | JSONB |
| datos_nuevos | JSONB |
| timestamp | TIMESTAMP |

:contentReference[oaicite:7]{index=7}

---

# Tabla: sesion_usuario

## Descripción

Control de sesiones activas de usuarios autenticados.

| Campo | Tipo |
|---|---|
| id_sesion | UUID |
| id_usuario | UUID |
| token_jwt | VARCHAR(500) |
| ip_origen | INET |
| fecha_inicio | TIMESTAMP |
| fecha_fin | TIMESTAMP |
| activa | BOOLEAN |

:contentReference[oaicite:8]{index=8}

---

# Tabla: asambleista

## Descripción

Representantes institucionales de la AIR.

| Campo | Tipo |
|---|---|
| id_asambleista | SERIAL |
| id_usuario | UUID |
| nombre_completo | VARCHAR(150) |
| cedula | VARCHAR(20) |
| correo | VARCHAR(150) |
| foto_url | TEXT |
| activo | BOOLEAN |
| fecha_registro | TIMESTAMP |

## Restricciones

- UNIQUE(cedula)
- Validación formato de cédula

:contentReference[oaicite:9]{index=9}

---

# Tabla: nombramiento

## Descripción

Nombramientos activos de asambleístas por sector.

| Campo | Tipo |
|---|---|
| id_nombramiento | SERIAL |
| id_asambleista | INT |
| id_sector | INT |
| fecha_inicio | DATE |
| fecha_fin | DATE |
| activo | BOOLEAN |

:contentReference[oaicite:10]{index=10}

---

# Tabla: bitacora_asambleista

## Descripción

Historial de cambios sobre asambleístas.

| Campo | Tipo |
|---|---|
| id_bitacora | SERIAL |
| id_asambleista | INTEGER |
| accion | VARCHAR(50) |
| descripcion | TEXT |
| fecha | TIMESTAMP |

:contentReference[oaicite:11]{index=11}

---

# Tabla: reglamento

## Descripción

Reglamentos institucionales registrados.

| Campo | Tipo |
|---|---|
| id_reglamento | SERIAL |
| nombre_normativa | VARCHAR(200) |
| sigla | VARCHAR(20) |
| emisor | VARCHAR(10) |
| fecha_registro | TIMESTAMP |

:contentReference[oaicite:12]{index=12}

---

# Tabla: elemento_normativo

## Descripción

Estructura jerárquica de reglamentos.

| Campo | Tipo |
|---|---|
| id_elemento | SERIAL |
| id_reglamento | INT |
| id_elemento_padre | INT |
| id_nivel_reglamento | INT |
| id_estado_vigencia | INT |
| numero_etiqueta | VARCHAR(20) |
| contenido_texto | TEXT |
| orden | INT |
| fecha_inicio_vigencia | DATE |
| fecha_fin_vigencia | DATE |

:contentReference[oaicite:13]{index=13}

---

# Tabla: propuesta

## Descripción

Propuestas y reformas institucionales.

| Campo | Tipo |
|---|---|
| id_propuesta | SERIAL |
| titulo | VARCHAR(255) |
| descripcion | TEXT |
| fecha_creacion | TIMESTAMP |
| id_etapa_propuesta | INT |
| id_estado_propuesta | INT |
| id_tipo_mayoria_requerida | INT |
| id_tipo_reforma | INT |

:contentReference[oaicite:14]{index=14}

---

# Tabla: bitacora_propuesta

## Descripción

Bitácora de movimientos de propuestas.

| Campo | Tipo |
|---|---|
| id_bitacora_propuesta | SERIAL |
| id_propuesta | INT |
| fecha_movimiento | TIMESTAMP |
| detalle | TEXT |

:contentReference[oaicite:15]{index=15}

---

# Tabla: proponente_propuesta

## Descripción

Relación entre propuestas y asambleístas proponentes.

| Campo | Tipo |
|---|---|
| id_proponente_propuesta | SERIAL |
| id_propuesta | INT |
| id_asambleista | INT |

:contentReference[oaicite:16]{index=16}

---

# Tabla: sesiones

## Descripción

Sesiones plenarias institucionales.

| Campo | Tipo |
|---|---|
| id_sesion | SERIAL |
| numero_sesion | INT |
| fecha | DATE |
| link_acta | TEXT |
| quorum_requerido | INT |

:contentReference[oaicite:17]{index=17}

---

# Tabla: acta

## Descripción

Actas asociadas a sesiones plenarias.

| Campo | Tipo |
|---|---|
| id_acta | SERIAL |
| id_sesion | INT |
| fecha_aprobacion | DATE |
| url_documento | TEXT |
| observaciones | TEXT |

:contentReference[oaicite:18]{index=18}

---

# Tabla: asistencia_sesion_plenaria

## Descripción

Registro de asistencia de asambleístas en sesiones plenarias.

| Campo | Tipo |
|---|---|
| id_asistencia | SERIAL |
| id_sesion | INT |
| id_asambleista | INT |
| id_estado_asistencia | INT |

:contentReference[oaicite:19]{index=19}

---

# Tabla: comision

## Descripción

Comisiones institucionales permanentes o especiales.

| Campo | Tipo |
|---|---|
| id_comision | SERIAL |
| nombre | VARCHAR(150) |
| id_tipo_comision | INT |
| fecha_creacion | DATE |
| fecha_disolucion | DATE |
| activa | BOOLEAN |

:contentReference[oaicite:20]{index=20}

---

# Tabla: sesion_comision

## Descripción

Sesiones realizadas por comisiones.

| Campo | Tipo |
|---|---|
| id_sesion_comision | SERIAL |
| id_comision | INT |
| numero_sesion | INT |
| fecha | DATE |
| link_acta | TEXT |
| quorum_requerido | INT |

:contentReference[oaicite:21]{index=21}

---

# Tabla: participacion_propuesta

## Descripción

Registro de participación de asambleístas en propuestas institucionales.

| Campo | Tipo |
|---|---|
| id_participacion | SERIAL |
| id_propuesta | INT |
| id_asambleista | INT |
| id_comision | INT |
| id_etapa_propuesta | INT |
| fecha_participacion | DATE |
| rol | VARCHAR(50) |
| observaciones | TEXT |

:contentReference[oaicite:22]{index=22}

---

# Relaciones Principales

| Tabla origen | Relación | Tabla destino |
|---|---|---|
| usuario | 1:N | usuario_rol |
| rol | 1:N | usuario_rol |
| rol | 1:N | rol_permiso |
| permiso | 1:N | rol_permiso |
| asambleista | 1:N | nombramiento |
| asambleista | 1:N | bitacora_asambleista |
| reglamento | 1:N | elemento_normativo |
| propuesta | 1:N | bitacora_propuesta |
| propuesta | N:M | asambleista |
| sesiones | 1:N | acta |
| comision | 1:N | sesion_comision |

---

# Arquitectura

El sistema utiliza arquitectura MVC:

- Models → acceso a datos
- Controllers → lógica de negocio
- Routes → endpoints REST
- Views → interfaces HTML

---

# Tecnologías Utilizadas

- Node.js
- Express
- PostgreSQL
- Supabase
- JWT
- HTML/CSS/JavaScript

---

# Estado Actual del Proyecto

## Implementado

- Gestión de usuarios
- Roles y permisos
- Auditoría
- Asambleístas
- Nombramientos
- Normativa institucional
- Propuestas y reformas
- Trazabilidad
- Sesiones plenarias
- Catálogos transversales

## Pendiente

- Certificaciones
- Votaciones avanzadas
- Compilador normativo
- Dashboard administrativo