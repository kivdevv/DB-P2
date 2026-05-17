# ISSUE #1: FOLIADO Y CONSECUTIVOS DAIR-XXX-YYYY

## Resumen
Sistema de generación automática y atómica de folios únicos (formato DAIR-XXX-YYYY) para la emisión de certificaciones. Incluye validación criptográfica y triggers de base de datos para garantizar la inalterabilidad (fe pública) y evitar condiciones de carrera (race conditions).

## Tablas Creadas

| Tabla | Propósito |
|-------|-----------|
| `control_folio` | Control anual secuencial de folios. Evita duplicidad mediante locks transaccionales. |
| `certificacion_emitida`| Almacena las certificaciones con su respectivo folio único, contenido y hash de seguridad. |

## Endpoints Implementados

### Protegidos (JWT)
- `GET /foliador/generar` - Obtiene y genera el siguiente folio único.
- `GET /foliador/ultimo` - Obtiene el último folio generado del año actual (acepta query `?año=YYYY`).

### Admin Only
- `GET /foliador/historial` - Ver el registro de auditoría e historial de folios generados.

## Seguridad e Integridad Implementada

- **Atomicidad (Anti Race-Conditions):** Uso de `FOR UPDATE` en consultas a `control_folio` para bloquear el registro temporalmente y asegurar que la secuencia (DAIR-XXX) nunca se duplique, incluso con peticiones simultáneas.
- **Fe Pública (No Repudio):** Implementación del Trigger `#2` (`tg_no_repudio_cert`) que bloquea a nivel de base de datos cualquier intento de `UPDATE` o `DELETE` sobre una certificación ya emitida.
- **Validación Criptográfica:** Generación de un hash SHA-256 nativo en el modelo combinando el contenido, el folio y la fecha de emisión para verificar la integridad del documento en el futuro.
- **Generación Automática:** Implementación del Trigger `#6` (`tg_folio_secuencial`) que intercepta los `INSERT` en `certificacion_emitida` y asigna el folio correcto dinámicamente.

## Roles y Permisos

| Rol | Permisos |
|-----|----------|
| Admin | Puede generar folios, consultar el último y ver el historial completo de folios anuales. |
| Editor | Puede generar folios y consultar el último emitido. No tiene acceso al historial. |
| Consulta | Puede consultar el último folio emitido (dependiendo de la configuración de acceso del módulo). |

## Testing

```bash
# Generar un nuevo folio
GET http://localhost:3000/foliador/generar
Header: Authorization: Bearer [token]

# Obtener el último folio de 2026
GET http://localhost:3000/foliador/ultimo?año=2026
Header: Authorization: Bearer [token]

# Obtener historial de folios (Solo Admin)
GET http://localhost:3000/foliador/historial
Header: Authorization: Bearer [token_admin]