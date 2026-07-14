import { Router } from 'express';
import { createReservation, getReservationsByUserId, cancelReservation } from '../controllers/reservation.controller.js';

const router = Router();

router.post('/', createReservation);
router.get('/user/:userId', getReservationsByUserId);
router.patch('/:id/cancel', cancelReservation);

export default router;
