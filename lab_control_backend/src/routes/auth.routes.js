import { Router } from 'express';
import { 
  register, 
  login, 
  requestTvPairing, 
  getTvPairingStatus, 
  pairTv,
  requestWatchPairing,
  getWatchPairingStatus,
  pairWatch
} from '../controllers/auth.controller.js';

const router = Router();

router.post('/register', register);
router.post('/login', login);

// TV Pairing Routes
router.post('/tv/request', requestTvPairing);
router.get('/tv/status/:code', getTvPairingStatus);
router.post('/tv/pair', pairTv);

// Watch Pairing Routes
router.post('/tv/watch/request', requestWatchPairing);
router.get('/tv/watch/status/:code', getWatchPairingStatus);
router.post('/tv/watch/pair', pairWatch);

export default router;