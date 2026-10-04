/**
 * SecureMart - API client.
 *
 * All application data flows: React -> fetch -> Express -> MySQL -> back.
 * The JWT is kept in localStorage and attached to every request.
 */

const API_BASE = '/api';
const TOKEN_KEY = 'securemart_token';

export function getToken() {
  return localStorage.getItem(TOKEN_KEY);
}

export function setToken(token) {
  if (token) localStorage.setItem(TOKEN_KEY, token);
  else localStorage.removeItem(TOKEN_KEY);
}

async function request(path, { method = 'GET', body, auth = true } = {}) {
  const headers = { 'Content-Type': 'application/json' };
  const token = getToken();
  if (auth && token) headers.Authorization = `Bearer ${token}`;

  const res = await fetch(`${API_BASE}${path}`, {
    method,
    headers,
    body: body !== undefined ? JSON.stringify(body) : undefined,
  });

  let data = null;
  const text = await res.text();
  if (text) {
    try {
      data = JSON.parse(text);
    } catch {
      data = { error: 'Unexpected server response.' };
    }
  }

  if (!res.ok) {
    const err = new Error((data && data.error) || `Request failed (${res.status})`);
    err.status = res.status;
    err.data = data;
    // A 401 means the token is missing/expired: drop it so the UI resets.
    if (res.status === 401) setToken(null);
    throw err;
  }
  return data;
}

export const api = {
  // auth
  register: (payload) => request('/auth/register', { method: 'POST', body: payload, auth: false }),
  login: (payload) => request('/auth/login', { method: 'POST', body: payload, auth: false }),
  logout: () => request('/auth/logout', { method: 'POST' }),
  me: () => request('/auth/me'),

  // products / categories
  products: (params = {}) => {
    const qs = new URLSearchParams(
      Object.entries(params).filter(([, v]) => v !== undefined && v !== null && v !== '')
    ).toString();
    return request(`/products${qs ? `?${qs}` : ''}`, { auth: false });
  },
  product: (id) => request(`/products/${id}`, { auth: false }),
  categories: () => request('/categories', { auth: false }),
  createProduct: (payload) => request('/products', { method: 'POST', body: payload }),
  updateProduct: (id, payload) => request(`/products/${id}`, { method: 'PUT', body: payload }),
  deleteProduct: (id) => request(`/products/${id}`, { method: 'DELETE' }),

  // cart
  cart: () => request('/cart'),
  addToCart: (productId, quantity = 1) => request('/cart', { method: 'POST', body: { productId, quantity } }),
  updateCartItem: (itemId, quantity) => request(`/cart/${itemId}`, { method: 'PUT', body: { quantity } }),
  removeCartItem: (itemId) => request(`/cart/${itemId}`, { method: 'DELETE' }),

  // orders
  orders: () => request('/orders'),
  order: (id) => request(`/orders/${id}`),
  checkout: (payload) => request('/orders', { method: 'POST', body: payload }),

  // profile
  profile: () => request('/users/profile'),
  updateProfile: (payload) => request('/users/profile', { method: 'PUT', body: payload }),

  // admin
  adminStats: () => request('/admin/stats'),
  adminUsers: () => request('/admin/users'),
  adminOrders: () => request('/admin/orders'),
  adminSecurity: () => request('/admin/security'),
};
