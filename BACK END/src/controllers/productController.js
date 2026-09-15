const { Product, Farm, User } = require('../models');
const { Op } = require('sequelize');
const fs = require('fs');
const path = require('path');

const saveBase64Image = (base64String) => {
  if (!base64String) return null;
  const cleanBase64 = base64String.replace(/^data:image\/\w+;base64,/, '');
  const buffer = Buffer.from(cleanBase64, 'base64');
  const uploadDir = path.join(__dirname, '../../uploads/products');
  if (!fs.existsSync(uploadDir)) {
    fs.mkdirSync(uploadDir, { recursive: true });
  }
  const safeName = `product_${Date.now()}_${Math.floor(Math.random() * 10000)}.jpg`;
  const filePath = path.join(uploadDir, safeName);
  fs.writeFileSync(filePath, buffer);
  return `/uploads/products/${safeName}`;
};

const getDefaultBackendImage = (category, name) => {
  const cat = (category || '').toLowerCase();
  const n = (name || '').toLowerCase();

  // 1. Strict category checks first
  if (cat.includes('egg') || cat.includes('oeuf') || n.includes('egg') || n.includes('oeuf')) {
    return '/uploads/products/product_eggs.jpg';
  }
  if (cat.includes('feed') || cat.includes('aliment') || cat.includes('provende') || n.includes('feed') || n.includes('mash')) {
    return '/uploads/products/product_feed.jpg';
  }
  if (cat.includes('meat') || cat.includes('viande')) {
    if (n.includes('whole') || n.includes('frais') || n.includes('fresh') || n.includes('dressed')) {
      return '/uploads/products/product_fresh_chicken.jpg';
    }
    return '/uploads/products/product_meat.jpg';
  }

  // 2. Live Poultry Subtypes
  const combined = `${cat} ${n}`;
  if (combined.includes('broiler') || combined.includes('chair')) {
    return '/uploads/products/product_broiler.jpg';
  }
  if (combined.includes('chick') || combined.includes('poussin') || combined.includes('day-old')) {
    return '/uploads/products/product_chicks.jpg';
  }
  if (combined.includes('layer') || combined.includes('pondeuse')) {
    return '/uploads/products/product_layer.jpg';
  }
  if (combined.includes('rooster') || combined.includes('coq') || combined.includes('cockerel')) {
    return '/uploads/products/product_rooster.jpg';
  }

  if (combined.includes('meat') || combined.includes('viande') || combined.includes('fillet')) {
    return '/uploads/products/product_meat.jpg';
  }

  return '/uploads/products/product_chicken.jpg';
};

const createProduct = async (req, res, next) => {
  try {
    const { farmId, name, description, price, stockQuantity, unit, category, imageUrl, imageBase64 } = req.body;

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

    let finalImageUrl = imageUrl;
    if (imageBase64) {
      finalImageUrl = saveBase64Image(imageBase64);
    }
    if (!finalImageUrl) {
      finalImageUrl = getDefaultBackendImage(category, name);
    }

    const product = await Product.create({
      farmId,
      name,
      description,
      price,
      stockQuantity: stockQuantity || 0,
      unit: unit || 'unit',
      category: category || 'Live Poultry',
      imageUrl: finalImageUrl
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
    if (category && category !== 'All') {
      const cat = category.toLowerCase();
      if (cat.includes('egg')) {
        whereClause.category = { [Op.like]: '%Egg%' };
      } else if (cat.includes('meat')) {
        whereClause.category = { [Op.like]: '%Meat%' };
      } else if (cat.includes('feed')) {
        whereClause.category = { [Op.like]: '%Feed%' };
      } else if (cat.includes('live')) {
        whereClause.category = { [Op.like]: '%Live%' };
      } else {
        whereClause.category = { [Op.like]: `%${category}%` };
      }
    }
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

    const { name, description, price, stockQuantity, unit, category, imageUrl, imageBase64, isAvailable } = req.body;
    if (name) product.name = name;
    if (description !== undefined) product.description = description;
    if (price !== undefined) product.price = price;
    if (stockQuantity !== undefined) product.stockQuantity = stockQuantity;
    if (unit) product.unit = unit;
    if (category) product.category = category;
    if (imageBase64) {
      product.imageUrl = saveBase64Image(imageBase64);
    } else if (imageUrl !== undefined) {
      product.imageUrl = imageUrl;
    }
    if (isAvailable !== undefined) product.isAvailable = isAvailable;

    await product.save();
    return res.json({ message: 'Product updated successfully', product });
  } catch (error) {
    next(error);
  }
};

const uploadProductImage = async (req, res, next) => {
  try {
    const { imageBase64 } = req.body;
    if (!imageBase64) {
      return res.status(400).json({ message: 'imageBase64 is required.' });
    }
    const uploadedUrl = saveBase64Image(imageBase64);
    return res.status(201).json({ message: 'Image uploaded successfully', imageUrl: uploadedUrl });
  } catch (error) {
    next(error);
  }
};

const getProductTemplates = async (req, res, next) => {
  try {
    const templates = [
      { name: 'Broiler Chicken', category: 'Live Poultry', imageUrl: '/uploads/products/product_broiler.jpg', defaultPrice: 4500, unit: 'bird' },
      { name: 'Layer Chicken', category: 'Live Poultry', imageUrl: '/uploads/products/product_layer.jpg', defaultPrice: 5000, unit: 'bird' },
      { name: 'Day-Old Chicks', category: 'Live Poultry', imageUrl: '/uploads/products/product_chicks.jpg', defaultPrice: 700, unit: 'chick' },
      { name: 'Mature Rooster', category: 'Live Poultry', imageUrl: '/uploads/products/product_rooster.jpg', defaultPrice: 6500, unit: 'bird' },
      { name: 'Farm-Fresh Whole Chicken', category: 'Poultry Meat', imageUrl: '/uploads/products/product_fresh_chicken.jpg', defaultPrice: 4000, unit: 'kg' },
      { name: 'Fresh Farm Eggs Tray', category: 'Eggs', imageUrl: '/uploads/products/product_eggs.jpg', defaultPrice: 2200, unit: 'tray' },
      { name: 'Poultry Cuts & Fillets', category: 'Poultry Meat', imageUrl: '/uploads/products/product_meat.jpg', defaultPrice: 3500, unit: 'kg' },
      { name: 'Nutritional Poultry Feed', category: 'Poultry Feed', imageUrl: '/uploads/products/product_feed.jpg', defaultPrice: 18500, unit: '50kg bag' },
    ];
    return res.json({ templates });
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
  deleteProduct,
  uploadProductImage,
  getProductTemplates
};
