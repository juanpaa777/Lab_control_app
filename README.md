# LabControl - App de Estudiantes 🎓📱

LabControl es una solución integral diseñada para gestionar de manera ágil y segura los préstamos de equipo tecnológico (placas de desarrollo, computadoras portátiles, routers, cables, etc.) en los laboratorios universitarios.

Este repositorio contiene la **Aplicación Móvil para Alumnos** desarrollada en Flutter y su respectivo **Servidor Backend REST** en Node.js con base de datos PostgreSQL dockerizada.

---

## 🛠️ Tecnologías y Arquitectura

### Frontend (Flutter Client)
*   **Patrón Arquitectónico**: *Clean Architecture* dividido en 4 capas desacopladas (`domain`, `infrastructure`, `presentation`, `config`).
*   **Gestión de Estado**: `Flutter Riverpod` para un flujo reactivo unidireccional de datos.
*   **Enrutamiento**: `GoRouter` con soporte de `StatefulShellRoute` para navegación independiente de pestañas.
*   **Cliente HTTP**: `Dio` para consumo de endpoints con interceptores de excepciones personalizados.
*   **Diseño**: Componentes interactivos basados en **Material 3** usando una paleta de colores universitarios (verde esmeralda como tono principal).

### Backend & Base de Datos
*   **Servidor REST**: Node.js con `Express` y módulos ES.
*   **Base de Datos**: PostgreSQL 15 ejecutándose dentro de un contenedor de `Docker`.
*   **Control de Stock y Concurrencia**: Transacciones SQL puras (`BEGIN`, `COMMIT`, `ROLLBACK`) y bloqueos de fila (`FOR UPDATE`) para evitar condiciones de carrera o sobreventa de stock en solicitudes simultáneas.
*   **Seguridad**: Cifrado y validación de contraseñas mediante `bcrypt`.

---

## 🚀 Requisitos Previos

Antes de comenzar, asegúrate de tener instalado:
*   [Flutter SDK](https://docs.flutter.dev/get-started/install) (versión >= 3.0.0)
*   [Node.js](https://nodejs.org/) (versión >= 18)
*   [Docker Desktop](https://www.docker.com/products/docker-desktop/) (debe estar abierto y ejecutándose el motor de contenedores)

---

## 💻 Guía de Instalación y Configuración

### 1. Levantar la Base de Datos (PostgreSQL en Docker)
El script de base de datos (`init-db.sql`) creará automáticamente el esquema de tablas y las semillas de prueba cuando levantes el contenedor por primera vez.

1. Abre tu terminal y navega a la carpeta del backend:
   ```bash
   cd lab_control_backend
   ```
2. Ejecuta Docker Compose en segundo plano:
   ```bash
   docker-compose up -d
   ```
   *Nota: La base de datos corre en el puerto redirigido `5433` para evitar conflictos con servicios nativos locales de PostgreSQL en tu computadora.*

### 2. Iniciar el Servidor Backend (Node.js)
1. Instala las dependencias necesarias:
   ```bash
   npm install
   ```
2. Arranca el servidor Express en modo desarrollo con nodemon:
   ```bash
   npm run dev
   ```
   El servidor estará disponible en `http://localhost:8080/api` y se conectará automáticamente a tu PostgreSQL en Docker.

### 3. Ejecutar la Aplicación Móvil (Flutter)
1. Regresa a la raíz del proyecto e instala los paquetes de Flutter:
   ```bash
   cd ..
   flutter pub get
   ```
2. Inicia tu emulador Android, simulador iOS o dispositivo de pruebas y ejecuta la app:
   ```bash
   flutter run
   ```

---

## 🔑 Credenciales de Prueba

Para iniciar sesión en la aplicación móvil de inmediato y probar el flujo de préstamos real, utiliza la siguiente cuenta precargada de prueba:
*   **Correo**: `diego.pardo@universidad.edu`
*   **Contraseña**: `password123`

---

## 📂 Estructura de la Aplicación Flutter

El código de la app está estructurado en base a **Clean Architecture**:
*   `lib/domain/`: Contiene el núcleo puro de la aplicación libre de dependencias externas.
    *   `entities/`: Objetos de negocio puros (`User`, `Equipment`, `Reservation`, etc.).
    *   `datasources/` y `repositories/`: Contratos e interfaces abstractas.
*   `lib/infrastructure/`: Implementaciones y procesamiento de datos.
    *   `models/` y `mappers/`: Serializadores de JSON y conversores a entidades.
    *   `datasources/`: Consumo real de la API REST mediante Dio (`api_auth_datasource.dart`, etc.) y mocks locales para desarrollo offline.
    *   `repositories/`: Implementaciones concretas de los repositorios que delegan llamadas al datasource.
*   `lib/presentation/`: Capa visual de UI y controladores.
    *   `providers/`: Gestión de estado global con Riverpod.
    *   `screens/` y `views/`: Pantallas completas y fragmentos de navegación inferior.
    *   `widgets/`: Componentes gráficos reutilizables.
*   `lib/config/`: Configuración global de la app (rutas con GoRouter, temas estéticos y helpers).
