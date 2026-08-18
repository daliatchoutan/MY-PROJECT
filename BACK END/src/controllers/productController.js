const { Product, Farm, User } = require('../models');
const { Op } = require('sequelize');

const createProduct = async (req, res, next) => {
  try {
    const { farmId, name, description, price, stockQuantity, unit, category, imageUrl } = req.body;

    if (!farmId || !name || price === undefined) {
      return res.status(400).json({ message: 'farmId, name, and price are required.' });
    }

    const farm = await Farm.findByPk(farmId);
    if (!farm) {
      return res.status(404).json({ message: 'Farm not found.' });
    }

    if (req.user.role === 'Farmer' && farm.farmerId !== req.user.id) {
      return res.status(403).json({ message: 'Forbidden. You can only add products to your own farm.' });
    }

    const product = await Product.create({
      farmId,
      name,
      description,
      price,
      stockQuantity: stockQuantity || 0,
      unit: unit || 'unit',
      category: category || 'Live Poultry',
      imageUrl
    });

    return res.status(201).json({ message: 'Product added successfully', product });
  } catch (error) {
    next(error);
  }
};

const getProducts = async (req, res, next) => {
  try {
    const { search, category, farmId, minPrice, maxPrice } = req.query;
    let whereClause = { isAvailable: true };

    if (farmId) whereClause.farmId = farmId;
    if (category) whereClause.category = category;
    if (search) {
      whereClause.name = { [Op.like]: `%${search}%` };
    }
    if (minPrice || maxPrice) {
      whereClause.price = {};
      if (minPrice) whereClause.price[Op.gte] = parseFloat(minPrice);
      if (maxPrice) whereClause.price[Op.lte] = parseFloat(maxPrice);
    }

    const products = await Product.findAll({
      where: whereClause,
      include: [{ model: Farm, as: 'farm', attributes: ['id', 'name', 'location'] }]
    });

    return res.json({ products });
  } catch (error) {
    next(error);
  }
};

const getProductById = async (req, res, next) => {
  try {
    const product = await Product.findByPk(req.params.id, {
      include: [{ model: Farm, as: 'farm', attributes: ['id', 'name', 'location'] }]
    });

    if (!product) {
      return res.status(404).json({ message: 'Product not found.' });
    }

    return res.json({ product });
  } catch (error) {
    next(error);
  }
};

const updateProduct = async (req, res, next) => {
  try {
    const product = await Product.findByPk(req.params.id, {
      include: [{ model: Farm, as: 'farm' }]
    });

    if (!product) {
      return res.status(404).json({ message: 'Product not found.' });
    }

    if (req.user.role === 'Farmer' && product.farm.farmerId !== req.user.id) {
      return res.status(403).json({ message: 'Forbidden. You do not own this product.' });
    }

    const { name, description, price, stockQuantity, unit, category, imageUrl, isAvailable } = req.body;
    if (name) product.name = name;
    if (description !== undefined) product.description = description;
    if (price !== undefined) product.price = price;
    if (stockQuantity !== undefined) product.stockQuantity = stockQuantity;
    if (unit) product.unit = unit;
    if (category) product.category = category;
    if (imageUrl !== undefined) product.imageUrl = imageUrl;
    if (isAvailable !== undefined) product.isAvailable = isAvailable;

    await product.save();
    return res.json({ message: 'Product updated successfully', product });
  } catch (error) {
    next(error);
  }
};

const deleteProduct = async (req, res, next) => {
  try {
    const product = await Product.findByPk(req.params.id, {
      include: [{ model: Farm, as: 'farm' }]
    });

    if (!product) {
      return res.status(404).json({ message: 'Product not found.' });
    }

    if (req.user.role === 'Farmer' && product.farm.farmerId !== req.user.id) {
      return res.status(403).json({ message: 'Forbidden. You do not own this product.' });
    }

    await product.destroy();
    return res.json({ message: 'Product deleted successfully' });
  } catch (error) {
    next(error);
  }
};

module.exports = {
  createProduct,
  getProducts,
  getProductById,
  updateProduct,
  deleteProduct
};
