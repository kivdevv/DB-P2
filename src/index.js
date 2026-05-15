require('dotenv').config();
const express = require('express');
const cors = require('cors');
const asambleistaRoutes =
require('./routes/asambleista.routes');
const path = require('path');
const AuthController = require('./controllers/AuthController');
const { verificarJWT, verificarRol } = require('./middleware/autenticacion');

const app = express();
app.use(cors());
const PORT = process.env.PORT || 3000;

app.use(express.json());
app.use(express.urlencoded({ extended: true }));
app.use(express.static(path.join(__dirname, 'views')));

// Logging 
app.use((req, res, next) => {
    console.log(`[${new Date().toISOString()}] ${req.method} ${req.path}`);
    next();
});

app.get('/health', (req, res) => {
    res.status(200).json({
        status: 'OK',
        servidor: 'Proyecto AIR - TEC',
        timestamp: new Date().toISOString(),
        version: '1.0.0'
    });
});

app.get('/', (req, res) => {
    res.status(200).json({
        mensaje: 'Bienvenido a la API del Proyecto AIR',
        endpoints_activos: [
            'POST /auth/registro',
            'POST /auth/login',
            'GET /auth/perfil (Requiere Token)',
            'POST /auth/logout (Requiere Token)'
        ]
    });
});

app.post('/auth/registro', AuthController.registro);
app.post('/auth/login', AuthController.login);
app.get('/auth/perfil', verificarJWT, AuthController.obtenerPerfil);
app.post('/auth/logout', verificarJWT, AuthController.logout);

const normativaRoutes = require('./routes/normativa.routes');
const catalogoRoutes = require('./routes/catalogo.routes');
app.use(normativaRoutes);
app.use(catalogoRoutes);
app.use('/asambleistas', asambleistaRoutes);

// Manejo de rutas no encontradas (404)
app.use((req, res) => {
    res.status(404).json({
        error: 'Ruta no encontrada',
        metodo: req.method,
        ruta: req.path
    });
});

// Manejo de errores globales (Para que el servidor no se apague si algo falla)
app.use((err, req, res, next) => {
    console.error('Error no capturado:', err);
    res.status(err.status || 500).json({
        error: err.message || 'Error interno del servidor',
        timestamp: new Date().toISOString()
    });
});



// Arrancar el motor
app.listen(PORT, () => {
    
    console.log(`Servidor AIR en http://localhost:${PORT}`);
    console.log(`Supabase: ${process.env.SUPABASE_URL ? 'Conectado' : 'ERROR: Falta SUPABASE_URL'}`);
    console.log(`JWT Secret: ${process.env.JWT_SECRET ? 'Configurado' : 'FALTA JWT_SECRET'}`);
});

module.exports = app;