/**
 * SecureMart - Product catalogue controller.
 * Public: list / search / filter / details.
 * Admin only: create / update / delete.
 *
 * All SQL uses parameterised queries (placeholders) so user input is never
 * concatenated into SQL text.
 */
const { pool } = require('../config/db');
const { toId, toMoney, toQty, isNonEmptyString } = require('../utils/validate');
const { audit } = require('../utils/audit');

const LIST_SQL = `
  SELECT p.id, p.name, p.slug, p.description, p.price, p.stock, p.image,
         p.is_active, p.category_id, c.name AS category, p.created_at
    FROM products p
    JOIN categories c ON c.id = p.category_id`;

/** GET /api/products?search=&category=&sort=&page=&limit= */
async function listProducts(req, res, next) {
  try {
    const search = typeof req.query.search === 'string' ? req.query.search.trim() : '';
    const category = typeof req.query.category === 'string' ? req.query.category.trim() : '';
    const sort = req.query.sort || 'newest';
    const page = Math.max(1, Number(req.query.page) || 1);
    const limit = Math.min(60, Math.max(1, Number(req.query.limit) || 12));
    const offset = (page - 1) * limit;

    const where = [];
    const params = [];

    if (search) {
      // Parameterised LIKE - input never becomes SQL text.
      where.push('(p.name LIKE ? OR p.description LIKE ?)');
      const like = `%${search}%`;
      params.push(like, like);
    }
    if (category) {
      where.push('c.slug = ?');
      params.push(category);
    }

    const whereSql = where.length ? `WHERE ${where.join(' AND ')}` : '';

    const orderMap = {
      newest: 'p.created_at DESC',
      price_asc: 'p.price ASC',
      price_desc: 'p.price DESC',
      name: 'p.name ASC',
    };
    const orderSql = orderMap[sort] || orderMap.newest;

    const [countRows] = await pool.execute(
      `SELECT COUNT(*) AS total FROM products p JOIN categories c ON c.id = p.category_id ${whereSql}`,
      params
    );
    const total = countRows[0].total;

    const [rows] = await pool.execute(
      `${LIST_SQL} ${whereSql} ORDER BY ${orderSql} LIMIT ${limit} OFFSET ${offset}`,
      params
    );

    return res.json({
      products: rows,
      pagination: { page, limit, total, pages: Math.ceil(total / limit) },
    });
  } catch (err) {
    return next(err);
  }
}

/** GET /api/products/:id */
async function getProduct(req, res, next) {
  try {
    const id = toId(req.params.id);
    if (!id) return res.status(400).json({ error: 'Invalid product id.' });

    const [rows] = await pool.execute(`${LIST_SQL} WHERE p.id = ?`, [id]);
    if (!rows[0]) return res.status(404).json({ error: 'Product not found.' });
    return res.json({ product: rows[0] });
  } catch (err) {
    return next(err);
  }
}

/** GET /api/categories - helper for filters/nav */
async function listCategories(req, res, next) {
  try {
    const [rows] = await pool.execute(
      `SELECT c.id, c.name, c.slug,
              (SELECT COUNT(*) FROM products p WHERE p.category_id = c.id) AS product_count
         FROM categories c ORDER BY c.name`
    );
    return res.json({ categories: rows });
  } catch (err) {
    return next(err);
  }
}

/** POST /api/products (admin) */
async function createProduct(req, res, next) {
  try {
    const { name, description, price, stock, image, category_id } = req.body || {};

    if (!isNonEmptyString(name) || name.length > 120) {
      return res.status(400).json({ error: 'Product name is required (max 120 chars).' });
    }
    if (!isNonEmptyString(description) || description.length > 2000) {
      return res.status(400).json({ error: 'Description is required (max 2000 chars).' });
    }
    const money = toMoney(price, -1);
    if (money < 0) return res.status(400).json({ error: 'Valid price is required.' });
    const qty = toQty(stock, 0);
    const catId = toId(category_id);
    if (!catId) return res.status(400).json({ error: 'Valid category_id is required.' });

    const slug = name.trim().toLowerCase().replace(/[^a-z0-9]+/g, '-').replace(/^-|-$/g, '').slice(0, 140);

    const [result] = await pool.execute(
      `INSERT INTO products (name, slug, description, price, stock, image, category_id)
       VALUES (?, ?, ?, ?, ?, ?, ?)`,
      [name.trim(), slug, description.trim(), money, qty, String(image || '').slice(0, 160), catId]
    );

    await audit({
      userId: req.user.id,
      eventType: 'PRODUCT_CREATED',
      description: `Created product #${result.insertId}`,
      req,
    });

    const [rows] = await pool.execute(`${LIST_SQL} WHERE p.id = ?`, [result.insertId]);
    return res.status(201).json({ product: rows[0] });
  } catch (err) {
    if (err.code === 'ER_DUP_ENTRY') {
      return res.status(409).json({ error: 'A product with that name already exists.' });
    }
    return next(err);
  }
}

/** PUT /api/products/:id (admin) */
async function updateProduct(req, res, next) {
  try {
    const id = toId(req.params.id);
    if (!id) return res.status(400).json({ error: 'Invalid product id.' });

    const [existing] = await pool.execute('SELECT id FROM products WHERE id = ?', [id]);
    if (!existing[0]) return res.status(404).json({ error: 'Product not found.' });

    const { name, description, price, stock, image, category_id, is_active } = req.body || {};
    const sets = [];
    const params = [];

    if (name !== undefined) {
      if (!isNonEmptyString(name) || name.length > 120) {
        return res.status(400).json({ error: 'Invalid name.' });
      }
      sets.push('name = ?');
      params.push(name.trim());
    }
    if (description !== undefined) {
      sets.push('description = ?');
      params.push(String(description).slice(0, 2000));
    }
    if (price !== undefined) {
      const money = toMoney(price, -1);
      if (money < 0) return res.status(400).json({ error: 'Invalid price.' });
      sets.push('price = ?');
      params.push(money);
    }
    if (stock !== undefined) {
      sets.push('stock = ?');
      params.push(toQty(stock, 0));
    }
    if (image !== undefined) {
      sets.push('image = ?');
      params.push(String(image).slice(0, 160));
    }
    if (category_id !== undefined) {
      const catId = toId(category_id);
      if (!catId) return res.status(400).json({ error: 'Invalid category_id.' });
      sets.push('category_id = ?');
      params.push(catId);
    }
    if (is_active !== undefined) {
      sets.push('is_active = ?');
      params.push(is_active ? 1 : 0);
    }

    if (!sets.length) return res.status(400).json({ error: 'No fields to update.' });

    params.push(id);
    await pool.execute(`UPDATE products SET ${sets.join(', ')} WHERE id = ?`, params);

    await audit({
      userId: req.user.id,
      eventType: 'PRODUCT_UPDATED',
      description: `Updated product #${id}`,
      req,
    });

    const [rows] = await pool.execute(`${LIST_SQL} WHERE p.id = ?`, [id]);
    return res.json({ product: rows[0] });
  } catch (err) {
    return next(err);
  }
}

/** DELETE /api/products/:id (admin) */
async function deleteProduct(req, res, next) {
  try {
    const id = toId(req.params.id);
    if (!id) return res.status(400).json({ error: 'Invalid product id.' });

    const [existing] = await pool.execute('SELECT id FROM products WHERE id = ?', [id]);
    if (!existing[0]) return res.status(404).json({ error: 'Product not found.' });

    await pool.execute('DELETE FROM products WHERE id = ?', [id]);

    await audit({
      userId: req.user.id,
      eventType: 'PRODUCT_DELETED',
      description: `Deleted product #${id}`,
      req,
    });

    return res.json({ message: 'Product deleted.' });
  } catch (err) {
    // FK restriction (product referenced by order history) -> safe message.
    if (err.code === 'ER_ROW_IS_REFERENCED_2' || err.errno === 1451) {
      return res.status(409).json({
        error: 'Cannot delete: product appears in existing orders. Deactivate it instead.',
      });
    }
    return next(err);
  }
}

module.exports = { listProducts, getProduct, listCategories, createProduct, updateProduct, deleteProduct };
