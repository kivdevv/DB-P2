# Issue #2 - Motor de Trazabilidad y Calculo de Participacion

## Modelo elegido: Opcion A - sesion_comision separada

Se creo `sesion_comision` como tabla paralela a `sesiones` (de Jimena, Issue #15) en lugar de modificarla.
La razon es que `sesiones` es generica y cubre solo plenarias via `asistencia_sesion_plenaria`.
Pedirle a Jimena que refactorice durante el sprint arriesga conflictos de merge y bloquea a los demas.
La vista `vw_trazabilidad_propuesta` reconcilia la informacion a traves de `participacion_propuesta`,
que es la tabla CORE donde se registra el paso de cada asambleista por cada etapa de cada propuesta.

---

## Diagrama de tablas (Issue #2)

```
catalogo_tipo_comision
  id_tipo_comision PK
  nombre, descripcion
        |
        | 1:N
        v
    comision
      id_comision PK
      nombre, id_tipo_comision FK, fecha_creacion, fecha_disolucion, activa
        |
        | 1:N
        v
  sesion_comision
    id_sesion_comision PK
    id_comision FK, numero_sesion, fecha, link_acta, quorum_requerido
        |
        | 1:N
        v
asistencia_sesion_comision
  id_asistencia_sc PK
  id_sesion_comision FK, id_asambleista FK, id_estado_asistencia FK


participacion_propuesta  <-- tabla CORE
  id_participacion PK
  id_propuesta FK --> propuesta
  id_asambleista FK --> asambleista
  id_comision FK (nullable) --> comision
  id_etapa_propuesta FK --> catalogo_etapas_propuestas
  fecha_participacion, rol, observaciones


vw_trazabilidad_propuesta  <-- vista principal
  JOIN participacion_propuesta
     + propuesta
     + asambleista
     + catalogo_etapas_propuestas
     + comision (LEFT JOIN)
  + fn_clausula_etapa_procedencia() como columna calculada
```

---

## Endpoints expuestos

| Metodo | Ruta | Descripcion | Auth |
|--------|------|-------------|------|
| GET | /api/trazabilidad/propuestas | Lista propuestas con etapa y estado actual | JWT |
| GET | /api/trazabilidad/propuesta/:id | Trazabilidad completa de una propuesta | JWT |
| GET | /api/trazabilidad/clausula/:id | Clausula legal segun etapa de procedencia | JWT |
| GET | /api/trazabilidad/comisiones | Lista comisiones activas | JWT |
| POST | /api/trazabilidad/participacion | Registra una participacion nueva | JWT + permiso TRAZABILIDAD_REGISTRAR o SECRETARIA_DAIR |

---

## Hotfixes aplicados en este issue

- `proponente_propuesta`: coma colgante antes del `);` y FK faltante a `asambleista`. Corregido directamente en el `CREATE TABLE`.
- `asistencia_sesion_plenaria`: mismo problema de coma colgante. Corregido para que el script ejecute limpio en BD fresca.

---

## Deuda tecnica

- `sesion_comision` es una tabla paralela a `sesiones`. En Sprint 3 podria refactorizarse a una sola tabla `sesion` con columna discriminadora `tipo_sesion` y FK opcional a `comision`. Esto requiere coordinar con Jimena y hacer una migracion que preserve los datos existentes.
- La funcion `fn_clausula_etapa_procedencia` hace match por nombre de etapa con `UPPER()`. Si el catalogo cambia de nombres, hay que actualizar el CASE. Una mejora futura seria agregar una columna `codigo` al catalogo para hacer el match por clave en lugar de texto libre.
