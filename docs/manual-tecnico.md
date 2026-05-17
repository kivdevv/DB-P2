# Manual Técnico — Proyecto AIR

## Sistema de Gestión Legislativa AIR

Instituto Tecnológico de Costa Rica  
Curso: Bases de Datos II  
Sprint 2

---

# Descripción General

El Sistema AIR tiene como propósito gestionar la trazabilidad legislativa de la Asamblea Institucional Representativa del TEC.

El sistema centraliza:
- propuestas y reformas;
- sesiones plenarias;
- certificaciones;
- normativa institucional;
- historial legislativo.

La implementación utiliza:
- PostgreSQL (Supabase);
- arquitectura MVC;
- Git/GitHub;
- vistas HTML estáticas iniciales.

---

# Módulos Implementados — Sprint 2

## 1. Módulo de Propuestas

Se implementaron las siguientes tablas:

### Tabla `propuesta`

Almacena:
- título;
- descripción;
- etapa legislativa;
- tipo de reforma;
- mayoría requerida.

### Tabla `bitacora_propuesta`

Permite mantener trazabilidad histórica de cambios y movimientos asociados a cada propuesta.

---

# Catálogos Implementados

- `catalogo_etapas_propuestas`
- `catalogo_estado_propuestas`
- `catalogo_tipo_mayoria_requerida`
- `catalogo_tipo_reforma`
- `catalogo_estado_vigencia`
- `catalogo_asistencia_sesion_comision`

---

# Módulo de Sesiones

## Tabla `sesiones`

Gestiona:
- número de sesión;
- fecha;
- quórum requerido;
- enlace al acta.

## Tabla `acta`

Relaciona las actas oficiales con cada sesión plenaria.

---

# Datos Semilla

Se agregaron datos iniciales para:
- catálogos;
- propuestas de ejemplo;
- sesiones de ejemplo.

---

# Vistas HTML Implementadas

## certificaciones/certificado-preview.view.html

Plantilla institucional de certificación oficial basada en formato DAIR.

Incluye:
- encabezado institucional;
- tabla de participaciones;
- cierre legal.

---

## normativa/visor.view.html

Vista inicial para consulta de reglamentos institucionales.

---

## normativa/reglamento-arbol.view.html

Representación jerárquica inicial del árbol normativo institucional.

---

# Tecnologías Utilizadas

- PostgreSQL
- Supabase
- HTML5
- CSS3
- Git
- GitHub
- Visual Studio Code

---

# Integración Pendiente Sprint 3

Las siguientes estructuras dependen de módulos externos:

- `proponente_propuesta`
- `asistencia_sesion_plenaria`

Estas tablas requieren integración con el módulo de asambleístas.

---

# Flujo de Trabajo Git

Se utilizó:
- rama `develop`;
- ramas `feature`;
- commits descriptivos;
- push mediante GitHub.

---

# Estado del Proyecto

Sprint 2 parcialmente completado con:
- estructura relacional inicial;
- vistas funcionales;
- datos semilla;
- integración Supabase.
