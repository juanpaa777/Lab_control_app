import { Router } from 'express';
import authRoutes from './auth.routes.js';
import equipmentRoutes from './equipment.routes.js';
import reservationRoutes from './reservation.routes.js';

const router = Router();

router.use('/auth', authRoutes);
router.use('/equipment', equipmentRoutes);
router.use('/reservations', reservationRoutes);

export default router;
