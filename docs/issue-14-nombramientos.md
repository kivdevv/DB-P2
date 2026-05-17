# ISSUE #14: GESTIÓN DE NOMBRAMIENTOS

## Resumen
Sistema para la administración de los períodos en los que un asambleísta ejerce representación dentro de un sector específico. Garantiza la integridad histórica de los datos y previene, mediante reglas de base de datos, que una misma persona ocupe representación en múltiples sectores de forma simultánea.

## Tablas Creadas

| Tabla | Propósito |
|-------|-----------|
| `sector` | Catálogo de sectores institucionales de representación (Docente, Estudiante, Administrativo, Directorio). |
| `nombramiento` | Registro del período (fechas de inicio y fin) y el estado (Activo, Histórico, Suspendido) de un asambleísta en un sector específico. |

## Endpoints Implementados

### Protegidos (JWT)
- `GET /nombramientos/:id_asambleista` - Obtener el historial completo de nombramientos de un asambleísta.
- `GET /nombramientos/:id_asambleista/actual` - Obtener exclusivamente el nombramiento activo actual.

### Editor & Admin
- `POST /nombramientos` - Crear y registrar un nuevo nombramiento (período).

### Admin Only
- `PUT /nombramientos/:id_nombramiento/finalizar` - Terminar un nombramiento de forma manual, pasando su estado a "Histórico" y cerrando su fecha de fin.

## Seguridad e Integridad Implementada

- **Integridad Histórica (Anti-Traslape):** Implementación del Trigger `#5` (`tg_traslape_sector`). Esta función se ejecuta antes de cada `INSERT` en `nombramiento` para validar matemáticamente que las fechas del nuevo período no choquen, rodeen o se crucen con un nombramiento activo del mismo asambleísta en otro sector.
- **Consistencia de Fechas:** Validaciones a nivel de base de datos (`CONSTRAINT ck_fechas`) y en el modelo del backend que aseguran que la `fecha_inicio` no pueda ser posterior a la `fecha_fin`.
- **Estados Lógicos:** Gestión automática de la vigencia mediante el control de la columna `estado` ('Activo' vs 'Histórico').

## Roles y Permisos

| Rol | Permisos |
|-----|----------|
| Admin | Acceso total. Puede crear nombramientos, consultar historiales y finalizar nombramientos activos prematura o manualmente. |
| Editor | Puede crear nuevos nombramientos y consultar historiales. No tiene permiso para finalizar nombramientos. |
| Consulta | Solo lectura. Puede visualizar el historial de nombramientos y el período actual de los asambleístas. |

## Testing

```bash
# Crear un nombramiento (Requiere rol Admin o Editor)
POST http://localhost:3000/nombramientos
Header: Authorization: Bearer [token]
{
  "id_asambleista": "uuid-asambleista-aqui",
  "id_sector": "uuid-sector-aqui",
  "fecha_inicio": "2026-01-01",
  "fecha_fin": "2026-12-31"
}

# Obtener historial completo de nombramientos
GET http://localhost:3000/nombramientos/uuid-asambleista
Header: Authorization: Bearer [token]

# Obtener solo el nombramiento activo actual
GET http://localhost:3000/nombramientos/uuid-asambleista/actual
Header: Authorization: Bearer [token]

# Finalizar nombramiento (Solo Admin)
PUT http://localhost:3000/nombramientos/uuid-nombramiento/finalizar
Header: Authorization: Bearer [token_admin]
{
  "fecha_fin": "2026-05-15"
}