import { Navigate, useLocation } from 'react-router-dom';
import { isAdminAuthenticated } from '../utils/adminSession';

export default function PrivateRoute({ children }) {
  const location = useLocation();
  return isAdminAuthenticated() ? children : <Navigate to="/login" replace state={{ from: location.pathname }} />;
}
