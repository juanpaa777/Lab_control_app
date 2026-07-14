import { Router } from 'express';
import { 
  getEquipmentList, 
  getEquipmentById, 
  getCategories,
  createEquipment,
  updateEquipment,
  deleteEquipment
} from '../controllers/equipment.controller.js';

const router = Router();

router.get('/', getEquipmentList);
router.get('/categories', getCategories);
router.get('/:id', getEquipmentById);

router.post('/', createEquipment);
router.put('/:id', updateEquipment);
router.delete('/:id', deleteEquipment);

export default router;
