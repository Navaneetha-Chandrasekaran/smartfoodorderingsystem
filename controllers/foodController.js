const Food = require('../models/foodmodel');

exports.addFood = (req, res) => {
    const { shop_id, name, price, availability, description } = req.body;

    if (!shop_id || !name || !price) {
        return res.status(400).json({ error: 'Shop ID, name, and price are required' });
    }

    Food.addFood(shop_id, name, price, availability, description, (err, result) => {
        if (err) return res.status(500).json({ error: err.message });
        res.json({ message: 'Food item added successfully', food_id: result.insertId });
    });
};

exports.updateFood = (req, res) => {
    const { name, price, availability, description } = req.body;
    const {id} = req.params;

    if (!id) return res.status(400).json({ error: 'Food ID is required' });

    Food.updateFood(id, name, price, availability, description, (err, result) => {
        if (err) return res.status(500).json({ error: err.message });
        res.json({ message: 'Food item updated successfully' });
    });
};


exports.deleteFood = (req, res) => {
    const food_id = req.params.id;

    if (!food_id) return res.status(400).json({ error: 'Food ID is required' });

    Food.deleteFood(food_id, (err, result) => {
        if (err) return res.status(500).json({ error: err.message });
        res.json({ message: 'Food item deleted successfully' });
    });
};

exports.getFoodByShop = (req, res) => {
    const shop_id = req.params.shop_id;

    if (!shop_id) return res.status(400).json({ error: 'Shop ID is required' });

    Food.getFoodByShop(shop_id, (err, results) => {
        if (err) return res.status(500).json({ error: err.message });
        res.json(results);
    });
};
