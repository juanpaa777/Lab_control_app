import express from 'express';
import cors from 'cors';
import dotenv from 'dotenv';
import apiRouter from './routes/index.js';
import pool from './config/db.js';

dotenv.config();

const app = express();
const PORT = process.env.PORT || 8080;

// Middlewares
app.use(cors());
app.use(express.json());

// Ruta de estado del servidor
app.get('/health', async (req, res) => {
  try {
    // Verificar conexión activa a base de datos
    await pool.query('SELECT NOW()');
    return res.json({ 
      status: 'OK', 
      message: 'LabControl Backend API is running smoothly', 
      database: 'Connected' 
    });
  } catch (err) {
    return res.status(500).json({ 
      status: 'ERROR', 
      message: 'Database connection failed', 
      error: err.message 
    });
  }
});

// Rutas principales
app.use('/api', apiRouter);

// Manejo de rutas no encontradas (404)
app.use((req, res) => {
  res.status(404).json({ error: 'Ruta no encontrada' });
});

// Manejo de errores global
app.use((err, req, res, next) => {
  console.error('Error no controlado:', err.stack);
  res.status(500).json({ error: 'Ocurrió un error interno en el servidor' });
});

// Arrancar servidor
app.listen(PORT, () => {
  console.log(`================================================`);
  console.log(`   Servidor LabControl corriendo en puerto ${PORT}   `);
  console.log(`   URL Base: http://localhost:${PORT}/api        `);
  console.log(`================================================`);
});
