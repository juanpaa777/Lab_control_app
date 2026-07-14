-- Habilitar la extensión para generar UUID v4
CREATE EXTENSION IF NOT EXISTS "uuid-ossp";

-- 1. Tabla de Usuarios (Alumnos)
CREATE TABLE IF NOT EXISTS users (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    name VARCHAR(100) NOT NULL,
    email VARCHAR(100) UNIQUE NOT NULL,
    password VARCHAR(255) NOT NULL,
    student_id VARCHAR(50) UNIQUE NOT NULL,
    career VARCHAR(100) NOT NULL,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

-- 2. Tabla de Categorías de Equipos
CREATE TABLE IF NOT EXISTS equipment_categories (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    name VARCHAR(50) UNIQUE NOT NULL,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

-- 3. Tabla de Equipos
CREATE TABLE IF NOT EXISTS equipment (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    name VARCHAR(100) NOT NULL,
    category_id UUID NOT NULL REFERENCES equipment_categories(id) ON DELETE RESTRICT,
    code VARCHAR(50) UNIQUE NOT NULL,
    location VARCHAR(150) NOT NULL,
    total_units INT NOT NULL CHECK (total_units >= 0),
    available_units INT NOT NULL CHECK (available_units >= 0 AND available_units <= total_units),
    image_url VARCHAR(255),
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

-- 4. Tabla de Reservas
CREATE TABLE IF NOT EXISTS reservations (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    user_id UUID NOT NULL REFERENCES users(id) ON DELETE CASCADE,
    equipment_id UUID NOT NULL REFERENCES equipment(id) ON DELETE RESTRICT,
    quantity INT NOT NULL CHECK (quantity > 0),
    pickup_date TIMESTAMP NOT NULL,
    return_date TIMESTAMP NOT NULL,
    status VARCHAR(20) DEFAULT 'pending' CHECK (status IN ('pending', 'active', 'completed', 'cancelled')),
    reservation_code VARCHAR(100) UNIQUE NOT NULL,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    CONSTRAINT check_dates CHECK (return_date > pickup_date)
);

-- Índices de búsqueda
CREATE INDEX IF NOT EXISTS idx_equipment_category ON equipment(category_id);
CREATE INDEX IF NOT EXISTS idx_reservations_user ON reservations(user_id);

-- Limpiar tablas si existieran
TRUNCATE TABLE reservations CASCADE;
TRUNCATE TABLE equipment CASCADE;
TRUNCATE TABLE equipment_categories CASCADE;
TRUNCATE TABLE users CASCADE;

-- Semilla de Categorías
INSERT INTO equipment_categories (id, name) VALUES 
('c1a2b3c4-d5e6-7f8a-9b0c-1d2e3f4a5b6c', 'Electrónica'),
('c2b3c4d5-e6f7-8a9b-0c1d-2e3f4a5b6c7d', 'Cómputo'),
('c3c4d5e6-f7a8-9b0c-1d2e-3f4a5b6c7d8e', 'Redes');

-- Semilla de Equipos
INSERT INTO equipment (id, name, category_id, code, location, total_units, available_units) VALUES
('e1a2b3c4-d5e6-7f8a-9b0c-1d2e3f4a5b6c', 'Kit Arduino Uno R3', 'c1a2b3c4-d5e6-7f8a-9b0c-1d2e3f4a5b6c', 'EQ-001', 'Laboratorio 3 - Planta Baja', 8, 3),
('e2b3c4d5-e6f7-8a9b-0c1d-2e3f4a5b6c7d', 'Laptop HP', 'c2b3c4d5-e6f7-8a9b-0c1d-2e3f4a5b6c7d', 'EQ-002', 'Laboratorio 2', 5, 2),
('e3c4d5e6-f7a8-9b0c-1d2e-3f4a5b6c7d8e', 'Cable USB-C', 'c1a2b3c4-d5e6-7f8a-9b0c-1d2e3f4a5b6c', 'EQ-003', 'Almacén de laboratorio', 15, 10),
('e4d5e6f7-a8b9-0c1d-2e3f-4a5b6c7d8e9f', 'Router Cisco', 'c3c4d5e6-f7a8-9b0c-1d2e-3f4a5b6c7d8e', 'EQ-004', 'Laboratorio de Redes', 4, 1);

-- Semilla de Estudiante de Prueba (Contraseña: password123, bcrypt hash: $2b$10$vI8aWB.7V25g9C.Vb50.O.uC61Hl1Xn2B/Lqy9i1cE/R0Qn.4gDra)
INSERT INTO users (id, name, email, password, student_id, career) VALUES
('f1a2b3c4-d5e6-7f8a-9b0c-1d2e3f4a5b6c', 'Diego Pardo', 'diego.pardo@universidad.edu', '$2b$10$p5GddS6a2.apB8bTvXUOu.6ckp1DoF0vtZR8lPoDC4N4vwttXt2RK', '202300123', 'Ingeniería en Sistemas');
