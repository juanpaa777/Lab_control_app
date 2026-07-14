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
