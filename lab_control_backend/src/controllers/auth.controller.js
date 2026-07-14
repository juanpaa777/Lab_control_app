import bcrypt from 'bcrypt';
import pool from '../config/db.js';

export const register = async (req, res) => {
  const { name, email, password, studentId, career } = req.body;

  if (!name || !email || !password || !studentId || !career) {
    return res.status(400).json({ error: 'Todos los campos son obligatorios' });
  }

  try {
    // 1. Verificar si el correo ya existe
    const userExist = await pool.query('SELECT id FROM users WHERE email = $1', [email]);
    if (userExist.rows.length > 0) {
      return res.status(400).json({ error: 'El correo electrónico ya está registrado' });
    }

    // 2. Verificar si la matrícula ya existe
    const studentExist = await pool.query('SELECT id FROM users WHERE student_id = $1', [studentId]);
    if (studentExist.rows.length > 0) {
      return res.status(400).json({ error: 'La matrícula ya está registrada' });
    }

    // 3. Hashear la contraseña
    const saltRounds = 10;
    const hashedPassword = await bcrypt.hash(password, saltRounds);

    // 4. Insertar en base de datos
    const result = await pool.query(
      `INSERT INTO users (name, email, password, student_id, career) 
       VALUES ($1, $2, $3, $4, $5) 
       RETURNING id, name, email, student_id AS "studentId", career`,
      [name, email, hashedPassword, studentId, career]
    );

    return res.status(201).json(result.rows[0]);
  } catch (error) {
    console.error('Error en registro:', error);
    return res.status(500).json({ error: 'Error del servidor en el registro' });
  }
};

export const login = async (req, res) => {
  const { email, password } = req.body;

  if (!email || !password) {
    return res.status(400).json({ error: 'Correo y contraseña son obligatorios' });
  }

  try {
    // 1. Buscar usuario
    const result = await pool.query(
      `SELECT id, name, email, password, student_id AS "studentId", career 
       FROM users WHERE email = $1`,
      [email]
    );

    if (result.rows.length === 0) {
      return res.status(400).json({ error: 'Credenciales inválidas' });
    }

    const user = result.rows[0];

    // 2. Comparar contraseñas
    const isMatch = await bcrypt.compare(password, user.password);
    if (!isMatch) {
      return res.status(400).json({ error: 'Credenciales inválidas' });
    }

    // 3. Retornar datos (sin contraseña)
    delete user.password;
    return res.json(user);
  } catch (error) {
    console.error('Error en login:', error);
    return res.status(500).json({ error: 'Error del servidor en el inicio de sesión' });
  }
};
