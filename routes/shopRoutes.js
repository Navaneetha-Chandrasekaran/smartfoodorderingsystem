const express = require('express');
const router = express.Router();
const shopController = require('../controllers/shopController');

router.post('/add-shop', shopController.createShop);
// router.get('/get-shops', shopController.getShops);
router.get('/get-shops', (req, res) => {
    shopController.getShops(req, res);
});
router.put('/updatestatus',shopController.updateShopStatus);

module.exports = router;
