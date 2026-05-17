# ISSUE #0: SEGURIDAD Y ROLES INSTITUCIONALES

## Resumen
Sistema de autenticación JWT con RBAC granular, auditoría automática y validación de permisos.

## Tablas Creadas

| Tabla | Propósito |
|-------|-----------|
| `usuario` | Usuarios del sistema (correo + contraseña) |
| `rol` | Roles: Admin, Editor, Consulta |
| `permiso` | 26 permisos granulares (CREAR_ASAMBLEISTA, etc.) |
| `usuario_rol` | Relación M:M usuario-rol |
| `rol_permiso` | Relación M:M rol-permiso |
| `audit_log` | Trazabilidad de cambios (INSERT/UPDATE/DELETE) |
| `sesion_usuario` | Seguimiento de logins activos |
| `intento_login_fallido` | Prevención de fuerza bruta |

## Endpoints Implementados

### Públicos
- `POST /auth/registro` - Registrar usuario
- `POST /auth/login` - Iniciar sesión

### Protegidos (JWT)
- `GET /auth/perfil` - Datos del usuario
- `POST /auth/logout` - Cerrar sesión
- `POST /auth/cambiar-contraseña` - Cambiar contraseña
- `GET /auth/permisos` - Ver permisos propios

### Admin Only
- `POST /admin/usuarios` - Crear usuario
- `GET /admin/usuarios` - Listar usuarios

## Seguridad Implementada

 **Autenticación:** JWT (24h expiración) + BCrypt (10 rounds)
 **RBAC:** Roles + Permisos granulares + Niveles de acceso (1-5)
 **Auditoría:** Trigger automático registra todos los cambios
 **Rate Limiting:** Máx 5 intentos de login en 15 min por IP
 **Validaciones:** Correo, contraseña (8+ char, mayúscula, número)

## Cambios Aplicados

-  **Eliminados de tabla `usuario`:** `nombre_completo`, `cedula`
  - **Razón:** Datos personales pertenecen a tabla `asambleista`, no a `usuario`
  - **Usuario ≠ Asambleista:** Un admin no necesita ser asambleista

-  **Controllers actualizados:** Removidas referencias a `nombre_completo` y `cedula` en registro, login y perfil

-  **Modelo Usuario actualizado:** Solo maneja correo + contraseña

## Testing

```bash
# Registro
POST http://localhost:3000/auth/registro
{
  "correo": "usuario@tec.ac.cr",
  "contraseña": "Test12345"
}

# Login
POST http://localhost:3000/auth/login
{
  "correo": "usuario@tec.ac.cr",
  "contraseña": "Test12345"
}

# Perfil (con JWT)
GET http://localhost:3000/auth/perfil
Header: Authorization: Bearer [token]
```

## Roles y Permisos

| Rol | Nivel | Permisos |
|-----|-------|----------|
| Admin | 3 | TODOS (26) |
| Editor | 2 | CRUD asambleistas, normativa, votos |
| Consulta | 1 | Solo lectura |

## Commits Realizados

1. `db(auth): crear tablas RBAC completo con triggers`
2. `feat(auth): actualizar modelo Usuario con métodos RBAC`
3. `feat(auth): agregar métodos cambiarContraseña y obtenerPermisos`
4. `feat(auth): agregar middlewares verificarPermiso, verificarNivelAcceso, limitarIntentos`
5. `fix(auth): corregir sintaxis rutas y documentación Issue #0`

## Status
✅ **COMPLETADO** - Sprint 2, Semana 1
