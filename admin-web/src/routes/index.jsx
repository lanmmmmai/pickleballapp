import { createBrowserRouter, Navigate } from "react-router-dom";
import AdminLayout from "../layouts/AdminLayout";
import LoginPage from "../pages/LoginPage";
import DashboardPage from "../pages/DashboardPage";
import UsersPage from "../pages/UsersPage";
import CourtsPage from "../pages/CourtsPage";
import BookingsPage from "../pages/BookingsPage";
import NotificationsPage from "../pages/NotificationsPage";
import VideosPage from "../pages/VideosPage";
import VouchersPage from "../pages/VouchersPage";
import CoinsPage from "../pages/CoinsPage";
import ProductsPage from "../pages/ProductsPage";
import ClassesPage from "../pages/ClassesPage";
import PrivateRoute from "../components/PrivateRoute";

const router = createBrowserRouter([
  { path: "/login", element: <LoginPage /> },
  {
    path: "/",
    element: (
      <PrivateRoute>
        <AdminLayout />
      </PrivateRoute>
    ),
    children: [
      { index: true, element: <Navigate to="/dashboard" replace /> },
      { path: "dashboard", element: <DashboardPage /> },
      { path: "users", element: <UsersPage /> },
      { path: "courts", element: <Navigate to="/products?type=COURT" replace /> },
      { path: "products", element: <ProductsPage /> },
      { path: "classes", element: <ClassesPage /> },
      { path: "bookings", element: <BookingsPage /> },
      { path: "notifications", element: <NotificationsPage /> },
      { path: "videos", element: <VideosPage /> },
      { path: "vouchers", element: <VouchersPage /> },
      { path: "coins", element: <CoinsPage /> },
    ],
  },
]);

export default router;
