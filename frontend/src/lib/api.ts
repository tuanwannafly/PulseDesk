import axios from 'axios';

const api = axios.create({
  baseURL: '',
  withCredentials: true,  // important: send Rails session cookie
  headers: {
    'Accept': 'application/json',
    'Content-Type': 'application/json',
    'X-Requested-With': 'XMLHttpRequest'  // Rails: protects CSRF
  }
});

// Centralised error toasting happens in callers; here we just normalise 401 -> logout redirect
api.interceptors.response.use(
  (r) => r,
  (err) => {
    if (err.response?.status === 401 && !location.pathname.startsWith('/login')) {
      location.href = '/login';
    }
    return Promise.reject(err);
  }
);

export default api;
