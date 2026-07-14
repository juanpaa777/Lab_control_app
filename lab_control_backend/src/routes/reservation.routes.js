import { Router } from 'express';
import { 
  createReservation, 
  getReservationsByUserId, 
  cancelReservation,
  getAllReservations,
  updateReservationStatus
} from '../controllers/reservation.controller.js';

const router = Router();

router.post('/', createReservation);
router.get('/', getAllReservations);
router.get('/user/:userId', getReservationsByUserId);
router.patch('/:id/status', updateReservationStatus);
router.patch('/:id/cancel', cancelReservation);

export default router;
