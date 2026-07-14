import { Router } from 'express';
import { getEquipmentList, getEquipmentById, getCategories } from '../controllers/equipment.controller.js';

const router = Router();

router.get('/', getEquipmentList);
router.get('/categories', getCategories);
router.get('/:id', getEquipmentById);

export default router;
