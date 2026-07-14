import pool from '../config/db.js';

export const getEquipmentList = async (req, res) => {
  const { search, category } = req.query;

  try {
    let queryText = `
      SELECT 
        e.id, 
        e.name, 
        e.code, 
        e.location, 
        e.total_units AS "totalUnits", 
        e.available_units AS "availableUnits", 
        e.image_url AS "imageUrl",
        json_build_object('id', c.id, 'name', c.name) AS category
      FROM equipment e
      JOIN equipment_categories c ON e.category_id = c.id
    `;
    
    const queryParams = [];
    const conditions = [];

    if (search) {
      queryParams.push(`%${search}%`);
      conditions.push(`(e.name ILIKE $${queryParams.length} OR e.code ILIKE $${queryParams.length} OR e.location ILIKE $${queryParams.length})`);
    }

    if (category) {
      queryParams.push(category);
      conditions.push(`e.category_id = $${queryParams.length}`);
    }

    if (conditions.length > 0) {
      queryText += ' WHERE ' + conditions.join(' AND ');
    }

    queryText += ' ORDER BY e.code ASC';

    const result = await pool.query(queryText, queryParams);
    return res.json(result.rows);
  } catch (error) {
    console.error('Error al obtener equipos:', error);
    return res.status(500).json({ error: 'Error al consultar inventario' });
  }
};

export const getEquipmentById = async (req, res) => {
  const { id } = req.params;

  try {
    const result = await pool.query(
      `SELECT 
        e.id, 
        e.name, 
        e.code, 
        e.location, 
        e.total_units AS "totalUnits", 
        e.available_units AS "availableUnits", 
        e.image_url AS "imageUrl",
        json_build_object('id', c.id, 'name', c.name) AS category
      FROM equipment e
      JOIN equipment_categories c ON e.category_id = c.id
      WHERE e.id = $1`,
      [id]
    );

    if (result.rows.length === 0) {
      return res.status(404).json({ error: 'Equipo no encontrado' });
    }

    return res.json(result.rows[0]);
  } catch (error) {
    console.error('Error al obtener equipo por id:', error);
    return res.status(500).json({ error: 'Error al consultar equipo' });
  }
};

export const getCategories = async (req, res) => {
  try {
    const result = await pool.query('SELECT id, name FROM equipment_categories ORDER BY name ASC');
    return res.json(result.rows);
  } catch (error) {
    console.error('Error al obtener categorías:', error);
    return res.status(500).json({ error: 'Error al consultar categorías' });
  }
};

export const createEquipment = async (req, res) => {
  const { name, categoryId, code, location, totalUnits, imageUrl } = req.body;

  if (!name || !categoryId || !code || !location || totalUnits === undefined) {
    return res.status(400).json({ error: 'Todos los campos son obligatorios' });
  }

  const units = parseInt(totalUnits);
  if (isNaN(units) || units < 0) {
    return res.status(400).json({ error: 'La cantidad total de unidades debe ser un número no negativo' });
  }

  try {
    const codeExist = await pool.query('SELECT id FROM equipment WHERE code = $1', [code]);
    if (codeExist.rows.length > 0) {
      return res.status(400).json({ error: 'El código del equipo ya está registrado' });
    }

    const result = await pool.query(
      `INSERT INTO equipment (name, category_id, code, location, total_units, available_units, image_url)
       VALUES ($1, $2, $3, $4, $5, $5, $6)
       RETURNING id, name, category_id AS "categoryId", code, location, total_units AS "totalUnits", available_units AS "availableUnits", image_url AS "imageUrl"`,
      [name, categoryId, code, location, units, imageUrl || '']
    );

    const newEq = result.rows[0];
    const catResult = await pool.query('SELECT name FROM equipment_categories WHERE id = $1', [categoryId]);
    const responseData = {
      id: newEq.id,
      name: newEq.name,
      code: newEq.code,
      location: newEq.location,
      totalUnits: newEq.totalUnits,
      availableUnits: newEq.availableUnits,
      imageUrl: newEq.imageUrl,
      category: {
        id: categoryId,
        name: catResult.rows[0]?.name || ''
      }
    };

    return res.status(201).json(responseData);
  } catch (error) {
    console.error('Error al crear equipo:', error);
    return res.status(500).json({ error: 'Error del servidor al registrar equipo' });
  }
};

export const updateEquipment = async (req, res) => {
  const { id } = req.params;
  const { name, categoryId, code, location, totalUnits, imageUrl } = req.body;

  if (!name || !categoryId || !code || !location || totalUnits === undefined) {
    return res.status(400).json({ error: 'Todos los campos son obligatorios' });
  }

  const units = parseInt(totalUnits);
  if (isNaN(units) || units < 0) {
    return res.status(400).json({ error: 'La cantidad total de unidades debe ser un número no negativo' });
  }

  try {
    const eqResult = await pool.query('SELECT total_units, available_units FROM equipment WHERE id = $1', [id]);
    if (eqResult.rows.length === 0) {
      return res.status(404).json({ error: 'Equipo no encontrado' });
    }

    const existingEq = eqResult.rows[0];
    const currentlyLent = existingEq.total_units - existingEq.available_units;
    if (units < currentlyLent) {
      return res.status(400).json({ 
        error: `No puedes reducir el stock total por debajo de las unidades actualmente en préstamo (${currentlyLent})` 
      });
    }

    const newAvailable = units - currentlyLent;

    const codeExist = await pool.query('SELECT id FROM equipment WHERE code = $1 AND id <> $2', [code, id]);
    if (codeExist.rows.length > 0) {
      return res.status(400).json({ error: 'El código del equipo ya está registrado por otro artículo' });
    }

    const updateResult = await pool.query(
      `UPDATE equipment 
       SET name = $1, category_id = $2, code = $3, location = $4, total_units = $5, available_units = $6, image_url = $7
       WHERE id = $8
       RETURNING id, name, category_id AS "categoryId", code, location, total_units AS "totalUnits", available_units AS "availableUnits", image_url AS "imageUrl"`,
      [name, categoryId, code, location, units, newAvailable, imageUrl || '', id]
    );

    const updatedEq = updateResult.rows[0];
    const catResult = await pool.query('SELECT name FROM equipment_categories WHERE id = $1', [categoryId]);
    const responseData = {
      id: updatedEq.id,
      name: updatedEq.name,
      code: updatedEq.code,
      location: updatedEq.location,
      totalUnits: updatedEq.totalUnits,
      availableUnits: updatedEq.availableUnits,
      imageUrl: updatedEq.imageUrl,
      category: {
        id: categoryId,
        name: catResult.rows[0]?.name || ''
      }
    };

    return res.json(responseData);
  } catch (error) {
    console.error('Error al actualizar equipo:', error);
    return res.status(500).json({ error: 'Error del servidor al actualizar equipo' });
  }
};

export const deleteEquipment = async (req, res) => {
  const { id } = req.params;

  try {
    const resCheck = await pool.query(
      `SELECT id FROM reservations WHERE equipment_id = $1 AND status IN ('pending', 'active')`,
      [id]
    );

    if (resCheck.rows.length > 0) {
      return res.status(400).json({ 
        error: 'No se puede eliminar el equipo porque tiene reservas activas o pendientes asociadas.' 
      });
    }

    await pool.query('DELETE FROM reservations WHERE equipment_id = $1', [id]);

    const result = await pool.query('DELETE FROM equipment WHERE id = $1 RETURNING id', [id]);
    if (result.rows.length === 0) {
      return res.status(404).json({ error: 'Equipo no encontrado' });
    }

    return res.json({ message: 'Equipo eliminado exitosamente' });
  } catch (error) {
    console.error('Error al eliminar equipo:', error);
    return res.status(500).json({ error: 'Error del servidor al eliminar equipo' });
  }
};
