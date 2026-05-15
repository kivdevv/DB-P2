# Sistema de Gestión Legislativa AIR

Proyecto del curso Bases de Datos II, segundo semestre 2025, Instituto Tecnológico de Costa Rica.

## Descripción

El sistema gestiona la actividad legislativa de la Asamblea Institucional 
Representativa (AIR) del TEC: padrón de asambleístas, normativa institucional, 
sesiones plenarias, comisiones de análisis y emisión de certificaciones con 
fe pública.

## Integrantes

- Jose Carlos Mora (lead técnico)
- Kevin
- Diana
- Jimena

## Stack tecnológico

- Node.js con Express para el servidor
- Supabase (PostgreSQL) como base de datos
- Arquitectura MVC
- Autenticación con JWT (en desarrollo)

## Instalación

1. Clonar el repositorio:
   ```
   git clone <url-del-repo>
   cd DB-P2
   ```

2. Instalar dependencias:
   ```
   npm install
   ```

3. Crear el archivo `.env` en la raíz con las credenciales de Supabase:
   ```
   SUPABASE_URL=https://tu-proyecto.supabase.co
   SUPABASE_ANON_KEY=tu-anon-key
   ```

4. Correr en desarrollo:
   ```
   npm run dev
   ```

## Estructura del proyecto

```
/
├── /database               # Script principal de la base de datos
│   ├── proyecto-air.sql  
├── /docs                   # Documentación del proyecto
├── /src
│   ├── /config             # Configuración de BD y seguridad
│   ├── /controllers        # Lógica de negocio
│   ├── /middleware         # Middleware JWT y autenticación
│   ├── /models             # Modelos de datos
│   ├── /routes             # Definición de endpoints
│   ├── /services           # Servicios auxiliares
│   ├── /views              # Interfaces HTML
│   ├── /logs               # Logs del sistema
│   └── index.js            # Punto principal del servidor
├── /tests                  # Pruebas
├── README.md
├── REGLAS_GIT.md
└── package.json
```

## Ramas

- `main`: entrega final (Sprint 3)
- `develop`: integración continua (Sprint 2)
- `feature/issue-N-descripcion`: desarrollo de funcionalidades

Ver `REGLAS_GIT.md` para la convención completa de commits y ramas.
