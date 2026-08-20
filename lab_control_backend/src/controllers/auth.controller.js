import bcrypt from 'bcrypt';
import pool from '../config/db.js';

export const register = async (req, res) => {
  const { name, email, password, studentId, career, role = 'student' } = req.body;

  if (!name || !email || !password) {
    return res.status(400).json({ error: 'Nombre, correo y contraseña son obligatorios' });
  }

  // 1. Validar nombre completo
  const trimmedName = name.trim();
  if (trimmedName.length < 3) {
    return res.status(400).json({ error: 'El nombre debe tener al menos 3 caracteres' });
  }
  if (!trimmedName.includes(' ')) {
    return res.status(400).json({ error: 'Debes ingresar nombre y apellido' });
  }
  if (!/^[a-zA-ZáéíóúÁÉÍÓÚñÑüÜ\s]+$/.test(trimmedName)) {
    return res.status(400).json({ error: 'El nombre solo debe contener letras' });
  }

  // 2. Validar correo institucional / formato general de email
  const emailRegex = /^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$/i;
  if (!emailRegex.test(email.trim())) {
    return res.status(400).json({ error: 'El correo electrónico no es válido' });
  }

  // 3. Validar contraseña fuerte (mínimo 8 caracteres, al menos 1 mayúscula, 1 minúscula y 1 número)
  if (password.length < 8) {
    return res.status(400).json({ error: 'La contraseña debe tener al menos 8 caracteres' });
  }
  if (!/[A-Z]/.test(password) || !/[a-z]/.test(password) || !/[0-9]/.test(password)) {
    return res.status(400).json({ error: 'La contraseña debe contener al menos una mayúscula, una minúscula y un número' });
  }

  if (role === 'admin') {
    return res.status(403).json({ error: 'No está permitido registrarse como administrador directamente' });
  }

  const validCareers = [
    'Desarrollo de software',
    'Redes',
    'Diseño Digital',
    'Entornos Virtuales',
    'Mecatronica',
    'procesos Industriales'
  ];

  if (role === 'student') {
    if (!studentId || !career) {
      return res.status(400).json({ error: 'Matrícula y carrera son obligatorias para estudiantes' });
    }
    // Validar matrícula del alumno: exactamente 10 dígitos numéricos
    if (!/^\d{10}$/.test(studentId.trim())) {
      return res.status(400).json({ error: 'La matrícula del alumno debe constar de exactamente 10 dígitos numéricos' });
    }
    // Validar que la carrera esté en la lista preestablecida
    if (!validCareers.includes(career.trim())) {
      return res.status(400).json({ error: 'La carrera seleccionada no es válida' });
    }
  }

  if (role === 'teacher') {
    if (!studentId || !studentId.trim()) {
      return res.status(400).json({ error: 'La matrícula es obligatoria para docentes' });
    }
    // Validar matrícula del docente: exactamente 10 dígitos numéricos
    if (!/^\d{10}$/.test(studentId.trim())) {
      return res.status(400).json({ error: 'La matrícula del docente debe constar de exactamente 10 dígitos numéricos' });
    }
  }

  try {
    const trimmedEmail = email.trim();
    const trimmedStudentId = studentId ? studentId.trim() : null;
    const trimmedCareer = career ? career.trim() : null;

    // 1. Verificar si el correo ya existe
    const userExist = await pool.query('SELECT id FROM users WHERE email = $1', [trimmedEmail]);
    if (userExist.rows.length > 0) {
      return res.status(400).json({ error: 'El correo electrónico ya está registrado' });
    }

    // 2. Verificar si la matrícula ya existe (si se proporciona)
    if (trimmedStudentId) {
      const studentExist = await pool.query('SELECT id FROM users WHERE student_id = $1', [trimmedStudentId]);
      if (studentExist.rows.length > 0) {
        return res.status(400).json({ error: 'La matrícula ya está registrada' });
      }
    }

    // 3. Hashear la contraseña
    const saltRounds = 10;
    const hashedPassword = await bcrypt.hash(password, saltRounds);

    // 4. Insertar en base de datos
    const result = await pool.query(
      `INSERT INTO users (name, email, password, student_id, career, role) 
       VALUES ($1, $2, $3, $4, $5, $6) 
       RETURNING id, name, email, student_id AS "studentId", career, role`,
      [trimmedName, trimmedEmail, hashedPassword, trimmedStudentId, trimmedCareer, role]
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
      `SELECT id, name, email, password, student_id AS "studentId", career, role 
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

// --- TV Device Pairing Endpoints ---
const tvPairings = new Map();
const generatePairingCode = () => {
  const chars = '0123456789';
  let code = '';
  for (let i = 0; i < 4; i++) {
    code += chars[Math.floor(Math.random() * chars.length)];
  }
  return `LC-${code}`;
};
export const requestTvPairing = async (req, res) => {
  const code = generatePairingCode();
  tvPairings.set(code, {
    status: 'pending',
    user: null,
    createdAt: Date.now()
  });

  // Expira en 5 minutos para liberar memoria
  setTimeout(() => {
    if (tvPairings.has(code) && tvPairings.get(code).status === 'pending') {
      tvPairings.delete(code);
    }
  }, 5 * 60 * 1000);
  return res.json({ code });
};
export const getTvPairingStatus = async (req, res) => {
  const { code } = req.params;
  const pairing = tvPairings.get(code.toUpperCase());
  if (!pairing) {
    return res.json({ status: 'expired' });
  }
  if (pairing.status === 'paired') {
    const user = pairing.user;
    tvPairings.delete(code.toUpperCase()); // Limpia tras verificación exitosa
    return res.json({ status: 'paired', user });
  }
  return res.json({ status: 'pending' });
};
export const pairTv = async (req, res) => {
  const { code, user } = req.body;
  if (!code || !user) {
    return res.status(400).json({ error: 'Código y datos del usuario son obligatorios' });
  }
  const pairing = tvPairings.get(code.toUpperCase());
  if (!pairing) {
    return res.status(404).json({ error: 'El código de vinculación no existe o ha expirado' });
  }
  if (pairing.status === 'paired') {
    return res.status(400).json({ error: 'Este código ya ha sido utilizado' });
  }
  pairing.status = 'paired';
  pairing.user = user;
  tvPairings.set(code.toUpperCase(), pairing);
  return res.json({ success: true });
};

// --- Wear OS Device Pairing Endpoints ---
const watchPairings = new Map();

const generateWatchPairingCode = () => {
  const chars = '0123456789';
  let code = '';
  for (let i = 0; i < 4; i++) {
    code += chars[Math.floor(Math.random() * chars.length)];
  }
  return `WR-${code}`; // Código prefijado con WR (Wear)
};

export const requestWatchPairing = async (req, res) => {
  const code = generateWatchPairingCode();
  watchPairings.set(code, {
    status: 'pending',
    user: null,
    createdAt: Date.now()
  });

  setTimeout(() => {
    if (watchPairings.has(code) && watchPairings.get(code).status === 'pending') {
      watchPairings.delete(code);
    }
  }, 5 * 60 * 1000);

  return res.json({ code });
};

export const getWatchPairingStatus = async (req, res) => {
  const { code } = req.params;
  const pairing = watchPairings.get(code.toUpperCase());

  if (!pairing) {
    return res.json({ status: 'expired' });
  }

  if (pairing.status === 'paired') {
    const user = pairing.user;
    watchPairings.delete(code.toUpperCase());
    return res.json({ status: 'paired', user });
  }

  return res.json({ status: 'pending' });
};

export const pairWatch = async (req, res) => {
  const { code, user } = req.body;

  if (!code || !user) {
    return res.status(400).json({ error: 'Código y datos del usuario son obligatorios' });
  }

  const pairing = watchPairings.get(code.toUpperCase());

  if (!pairing) {
    return res.status(404).json({ error: 'El código de vinculación no existe o ha expirado' });
  }

  if (pairing.status === 'paired') {
    return res.status(400).json({ error: 'Este código ya ha sido utilizado' });
  }

  pairing.status = 'paired';
  pairing.user = user;
  watchPairings.set(code.toUpperCase(), pairing);

  return res.json({ success: true });
};