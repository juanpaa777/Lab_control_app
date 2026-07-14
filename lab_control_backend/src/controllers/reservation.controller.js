import pool from '../config/db.js';

export const createReservation = async (req, res) => {
  const { userId, equipmentId, quantity, pickupDate, returnDate } = req.body;

  if (!userId || !equipmentId || !quantity || !pickupDate || !returnDate) {
    return res.status(400).json({ error: 'Todos los campos son obligatorios' });
  }

  const qty = parseInt(quantity);
  if (isNaN(qty) || qty <= 0) {
    return res.status(400).json({ error: 'La cantidad debe ser mayor a cero' });
  }

  const pickup = new Date(pickupDate);
  const returnDt = new Date(returnDate);

  // Validaciones de fechas
  const now = new Date();
  const marginNow = new Date(now.getTime() - 5 * 60 * 1000); // 5 min de tolerancia
  if (pickup.getTime() < marginNow.getTime()) {
    return res.status(400).json({ error: 'La fecha de recogida no puede estar en el pasado' });
  }

  if (returnDt.getTime() <= pickup.getTime()) {
    return res.status(400).json({ error: 'La fecha de devolución debe ser posterior a la de recogida' });
  }

  // Iniciar Cliente de la base de datos para la Transacción
  const client = await pool.connect();

  try {
    // 1. Iniciar Transacción
    await client.query('BEGIN');

    // 2. Obtener equipo y bloquear la fila para escritura (FOR UPDATE)
    const eqResult = await client.query(
      `SELECT id, name, code, location, total_units, available_units, category_id, image_url 
       FROM equipment WHERE id = $1 FOR UPDATE`,
      [equipmentId]
    );

    if (eqResult.rows.length === 0) {
      await client.query('ROLLBACK');
      return res.status(404).json({ error: 'El equipo especificado no existe' });
    }

    const equipment = eqResult.rows[0];

    // 3. Validar disponibilidad
    if (equipment.available_units <= 0) {
      await client.query('ROLLBACK');
      return res.status(400).json({ error: 'El equipo no cuenta con unidades disponibles para préstamo' });
    }

    if (qty > equipment.available_units) {
      await client.query('ROLLBACK');
      return res.status(400).json({ 
        error: `La cantidad solicitada (${qty}) supera las unidades disponibles (${equipment.available_units})` 
      });
    }

    // 4. Reducir stock del equipo
    const newAvailableUnits = equipment.available_units - qty;
    await client.query(
      'UPDATE equipment SET available_units = $1 WHERE id = $2',
      [newAvailableUnits, equipmentId]
    );

    // 5. Generar código único para el QR
    const reservationCode = `labcontrol-res-${Date.now()}-${userId.substring(0, 5)}-${equipment.code}`;

    // 6. Registrar la reserva
    const resResult = await client.query(
      `INSERT INTO reservations (user_id, equipment_id, quantity, pickup_date, return_date, status, reservation_code)
       VALUES ($1, $2, $3, $4, $5, 'pending', $6)
       RETURNING id, user_id AS "userId", quantity, pickup_date AS "pickupDate", return_date AS "returnDate", status, reservation_code AS "qrCode"`,
      [userId, equipmentId, qty, pickup, returnDt, reservationCode]
    );

    const savedReservation = resResult.rows[0];

    // 7. Consolidar cambios (COMMIT)
    await client.query('COMMIT');

    // Estructurar respuesta uniendo detalles del equipo actualizado
    // Obtener la categoría del equipo para completar el mapeo en Flutter
    const catResult = await client.query('SELECT name FROM equipment_categories WHERE id = $1', [equipment.category_id]);
    
    const responseData = {
      ...savedReservation,
      equipment: {
        id: equipment.id,
        name: equipment.name,
        code: equipment.code,
        location: equipment.location,
        totalUnits: equipment.total_units,
        availableUnits: newAvailableUnits,
        imageUrl: equipment.image_url,
        category: {
          id: equipment.category_id,
          name: catResult.rows[0]?.name || ''
        }
      }
    };

    return res.status(201).json(responseData);
  } catch (error) {
    // Si hay error, hacer deshacer cambios (ROLLBACK)
    await client.query('ROLLBACK');
    console.error('Error al realizar la reserva (rollback ejecutado):', error);
    return res.status(500).json({ error: 'Error del servidor al registrar la reserva' });
  } finally {
    // Liberar cliente
    client.release();
  }
};

export const getReservationsByUserId = async (req, res) => {
  const { userId } = req.params;

  try {
    const queryText = `
      SELECT 
        r.id, 
        r.user_id AS "userId", 
        r.quantity, 
        r.pickup_date AS "pickupDate", 
        r.return_date AS "returnDate", 
        r.status, 
        r.reservation_code AS "qrCode",
        json_build_object(
          'id', e.id,
          'name', e.name,
          'code', e.code,
          'location', e.location,
          'totalUnits', e.total_units,
          'availableUnits', e.available_units,
          'imageUrl', e.image_url,
          'category', json_build_object('id', c.id, 'name', c.name)
        ) AS equipment
      FROM reservations r
      JOIN equipment e ON r.equipment_id = e.id
      JOIN equipment_categories c ON e.category_id = c.id
      WHERE r.user_id = $1
      ORDER BY r.created_at DESC
    `;

    const result = await pool.query(queryText, [userId]);
    return res.json(result.rows);
  } catch (error) {
    console.error('Error al obtener reservas por usuario:', error);
    return res.status(500).json({ error: 'Error al consultar reservas' });
  }
};

export const cancelReservation = async (req, res) => {
  const { id } = req.params;

  const client = await pool.connect();

  try {
    await client.query('BEGIN');

    // 1. Obtener la reserva y bloquearla
    const resResult = await client.query(
      'SELECT id, equipment_id, quantity, status FROM reservations WHERE id = $1 FOR UPDATE',
      [id]
    );

    if (resResult.rows.length === 0) {
      await client.query('ROLLBACK');
      return res.status(404).json({ error: 'Reserva no encontrada' });
    }

    const reservation = resResult.rows[0];

    if (reservation.status === 'cancelled') {
      await client.query('ROLLBACK');
      return res.status(400).json({ error: 'La reserva ya se encuentra cancelada' });
    }

    if (reservation.status === 'completed') {
      await client.query('ROLLBACK');
      return res.status(400).json({ error: 'No se puede cancelar una reserva ya devuelta/finalizada' });
    }

    // 2. Cambiar estado de la reserva
    const updateResult = await client.query(
      `UPDATE reservations SET status = 'cancelled' WHERE id = $1 
       RETURNING id, user_id AS "userId", quantity, pickup_date AS "pickupDate", return_date AS "returnDate", status, reservation_code AS "qrCode"`,
      [id]
    );

    const updatedRes = updateResult.rows[0];

    // 3. Devolver stock al equipo
    const eqResult = await client.query(
      'SELECT available_units FROM equipment WHERE id = $1 FOR UPDATE',
      [reservation.equipment_id]
    );
    
    let newAvailableUnits = 0;
    if (eqResult.rows.length > 0) {
      newAvailableUnits = eqResult.rows[0].available_units + reservation.quantity;
      await client.query(
        'UPDATE equipment SET available_units = $1 WHERE id = $2',
        [newAvailableUnits, reservation.equipment_id]
      );
    }

    await client.query('COMMIT');

    // Completar detalles para respuesta
    const eqDetails = await client.query(
      `SELECT e.id, e.name, e.code, e.location, e.total_units, e.image_url,
              json_build_object('id', c.id, 'name', c.name) AS category
       FROM equipment e 
       JOIN equipment_categories c ON e.category_id = c.id 
       WHERE e.id = $1`,
      [reservation.equipment_id]
    );

    const equipment = eqDetails.rows[0];

    const responseData = {
      ...updatedRes,
      equipment: {
        id: equipment.id,
        name: equipment.name,
        code: equipment.code,
        location: equipment.location,
        totalUnits: equipment.total_units,
        availableUnits: newAvailableUnits,
        imageUrl: equipment.image_url,
        category: equipment.category
      }
    };

    return res.json(responseData);
  } catch (error) {
    await client.query('ROLLBACK');
    console.error('Error al cancelar reserva:', error);
    return res.status(500).json({ error: 'Error del servidor al cancelar la reserva' });
  } finally {
    client.release();
  }
};

export const getAllReservations = async (req, res) => {
  try {
    const queryText = `
      SELECT 
        r.id, 
        r.user_id AS "userId", 
        r.quantity, 
        r.pickup_date AS "pickupDate", 
        r.return_date AS "returnDate", 
        r.status, 
        r.reservation_code AS "qrCode",
        json_build_object(
          'id', e.id,
          'name', e.name,
          'code', e.code,
          'location', e.location,
          'totalUnits', e.total_units,
          'availableUnits', e.available_units,
          'imageUrl', e.image_url,
          'category', json_build_object('id', c.id, 'name', c.name)
        ) AS equipment,
        u.name AS "userName",
        u.email AS "userEmail",
        u.student_id AS "studentId",
        u.career AS "userCareer"
      FROM reservations r
      JOIN equipment e ON r.equipment_id = e.id
      JOIN equipment_categories c ON e.category_id = c.id
      JOIN users u ON r.user_id = u.id
      ORDER BY r.created_at DESC
    `;

    const result = await pool.query(queryText);
    return res.json(result.rows);
  } catch (error) {
    console.error('Error al obtener todas las reservas:', error);
    return res.status(500).json({ error: 'Error al consultar reservas' });
  }
};

export const updateReservationStatus = async (req, res) => {
  const { id } = req.params;
  const { status } = req.body;

  if (!status || !['pending', 'active', 'completed', 'cancelled'].includes(status)) {
    return res.status(400).json({ error: 'Estado inválido' });
  }

  const client = await pool.connect();

  try {
    await client.query('BEGIN');

    const resResult = await client.query(
      'SELECT id, equipment_id, quantity, status FROM reservations WHERE id = $1 FOR UPDATE',
      [id]
    );

    if (resResult.rows.length === 0) {
      await client.query('ROLLBACK');
      return res.status(404).json({ error: 'Reserva no encontrada' });
    }

    const reservation = resResult.rows[0];
    const oldStatus = reservation.status;

    if (oldStatus === status) {
      await client.query('ROLLBACK');
      return res.status(400).json({ error: `La reserva ya tiene el estado ${status}` });
    }

    const isOldRestoring = oldStatus === 'completed' || oldStatus === 'cancelled';
    const isNewRestoring = status === 'completed' || status === 'cancelled';

    if (!isOldRestoring && isNewRestoring) {
      const eqResult = await client.query(
        'SELECT available_units FROM equipment WHERE id = $1 FOR UPDATE',
        [reservation.equipment_id]
      );
      if (eqResult.rows.length > 0) {
        const newAvailableUnits = eqResult.rows[0].available_units + reservation.quantity;
        await client.query(
          'UPDATE equipment SET available_units = $1 WHERE id = $2',
          [newAvailableUnits, reservation.equipment_id]
        );
      }
    } else if (isOldRestoring && !isNewRestoring) {
      const eqResult = await client.query(
        'SELECT available_units FROM equipment WHERE id = $1 FOR UPDATE',
        [reservation.equipment_id]
      );
      if (eqResult.rows.length > 0) {
        const available = eqResult.rows[0].available_units;
        if (available < reservation.quantity) {
          await client.query('ROLLBACK');
          return res.status(400).json({ error: 'No hay suficiente stock disponible para reactivar la reserva' });
        }
        const newAvailableUnits = available - reservation.quantity;
        await client.query(
          'UPDATE equipment SET available_units = $1 WHERE id = $2',
          [newAvailableUnits, reservation.equipment_id]
        );
      }
    }

    const updateResult = await client.query(
      `UPDATE reservations SET status = $1 WHERE id = $2 
       RETURNING id, user_id AS "userId", quantity, pickup_date AS "pickupDate", return_date AS "returnDate", status, reservation_code AS "qrCode"`,
      [status, id]
    );

    const updatedRes = updateResult.rows[0];

    const eqDetails = await client.query(
      `SELECT e.id, e.name, e.code, e.location, e.total_units, e.available_units, e.image_url,
              json_build_object('id', c.id, 'name', c.name) AS category
       FROM equipment e 
       JOIN equipment_categories c ON e.category_id = c.id 
       WHERE e.id = $1`,
      [reservation.equipment_id]
    );

    const equipment = eqDetails.rows[0];

    await client.query('COMMIT');

    const responseData = {
      ...updatedRes,
      equipment: {
        id: equipment.id,
        name: equipment.name,
        code: equipment.code,
        location: equipment.location,
        totalUnits: equipment.total_units,
        availableUnits: equipment.available_units,
        imageUrl: equipment.image_url,
        category: equipment.category
      }
    };

    return res.json(responseData);
  } catch (error) {
    await client.query('ROLLBACK');
    console.error('Error al actualizar estado de reserva:', error);
    return res.status(500).json({ error: 'Error del servidor al actualizar reserva' });
  } finally {
    client.release();
  }
};
