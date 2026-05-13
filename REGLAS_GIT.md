# Reglas de Git — Proyecto AIR

Estas son las reglas que seguimos en el equipo para mantener el historial limpio y cumplir con los requisitos del profesor.

## Convención de commits

El formato es:

```
tipo(modulo): descripcion corta en presente
```

### Tipos

| Tipo | Cuándo usarlo |
|------|---------------|
| `feat` | Se agrega funcionalidad nueva |
| `fix` | Se corrige un bug |
| `db` | Cambios en el esquema SQL o migraciones |
| `docs` | Documentación, README, comentarios |

### Ejemplos correctos

```
feat(asambleistas): agregar endpoint para registrar asambleísta
fix(sesiones): corregir validación de fecha en sesión plenaria
db(normativa): agregar tabla de versiones de ley
docs(readme): actualizar instrucciones de instalación
```

### Ejemplos incorrectos (penalizados)

```
actualizacion
cambios varios
fix
subir avance
wip
```

## Estructura de ramas

```
main
└── develop
    ├── feature/issue-1-modelo-asambleistas
    ├── feature/issue-2-crud-normativa
    └── feature/issue-N-descripcion
```

- Toda funcionalidad nueva sale de `develop` como `feature/issue-N-descripcion`.
- Cuando está lista, se hace merge a `develop` mediante pull request.
- Al final del Sprint 3, `develop` se mergea a `main` para la entrega final.

## Entrega por sprint

- **Sprint 2**: todo el trabajo va en `develop`. No se toca `main`.
- **Sprint 3**: entrega final en `main` mediante merge desde `develop`.

## Penalizaciones del profesor

| Infracción | Penalización |
|------------|-------------|
| Commit con mensaje genérico (ej: "cambios", "fix", "update") | -5% |
| Estructura de ramas incorrecta | -10% |
| Código entregado fuera de la rama correspondiente | 0 puntos en esa sección |

## Flujo de trabajo típico

1. Crear issue en GitHub para la tarea.
2. Crear rama desde `develop`: `git checkout -b feature/issue-N-descripcion`
3. Hacer commits siguiendo la convención.
4. Abrir pull request hacia `develop`.
5. Otro integrante revisa y aprueba.
6. Merge y borrar la rama de feature.
