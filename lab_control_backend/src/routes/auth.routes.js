import { Router } from 'express';
import { 
  register, 
  login, 
  requestTvPairing, 
  getTvPairingStatus, 
  pairTv 
} from '../controllers/auth.controller.js';
const router = Router();
router.post('/register', register);
router.post('/login', login);
// TV Pairing Routes
router.post('/tv/request', requestTvPairing);
router.get('/tv/status/:code', getTvPairingStatus);
router.post('/tv/pair', pairTv);
export default router;
