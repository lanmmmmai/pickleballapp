import axios from 'axios';
import { clearAdminSession, getAdminToken } from '../utils/adminSession';

const api = axios.create({
  baseURL: 'http://127.0.0.1:3000/api',
});

api.interceptors.request.use((config) => {
  const token = getAdminToken();
  if (token) {
    config.headers.Authorization = `Bearer ${token}`;
  }
  return config;
});

api.interceptors.response.use(
  (response) => response,
  (error) => {
    if (error.response?.status === 401) {
      clearAdminSession();
    }
    return Promise.reject(error);
  }
);

export default api;
