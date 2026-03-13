import { useEffect, useState } from "react";
import api from "../services/api";

const defaultForm = {
  name: "",
  email: "",
  phone: "",
  password: "",
  role: "USER",
  emailVerified: true,
};

function renderAvatar(user) {
  const name = (user.name || user.email || "User").trim();
  const initial = name ? name[0].toUpperCase() : "U";
  const avatarUrl = (user.avatarUrl || "").trim();

  if (avatarUrl) {
    return (
      <img
        src={avatarUrl}
        alt={name}
        style={{
          width: 44,
          height: 44,
          borderRadius: "50%",
          objectFit: "cover",
          border: "2px solid #eaf7f0",
        }}
      />
    );
  }

  return (
    <div
      style={{
        width: 44,
        height: 44,
        borderRadius: "50%",
        background: "#eaf7f0",
        color: "#0a7e4f",
        display: "grid",
        placeItems: "center",
        fontWeight: 800,
      }}
    >
      {initial}
    </div>
  );
}

export default function UsersPage() {
  const [users, setUsers] = useState([]);
  const [loading, setLoading] = useState(true);
  const [error, setError] = useState("");
  const [showForm, setShowForm] = useState(false);
  const [editingUserId, setEditingUserId] = useState(null);
  const [submitting, setSubmitting] = useState(false);
  const [form, setForm] = useState(defaultForm);
  const [previewUser, setPreviewUser] = useState(null);

  const fetchUsers = async () => {
    try {
      setLoading(true);
      setError("");
      const res = await api.get("/users");
      setUsers(res.data?.data || []);
    } catch (err) {
      console.error(err);
      setError("Không tải được danh sách user");
      setUsers([]);
    } finally {
      setLoading(false);
    }
  };

  useEffect(() => {
    fetchUsers();
  }, []);

  const resetForm = () => {
    setForm(defaultForm);
    setEditingUserId(null);
    setShowForm(false);
    setError("");
  };

  const handleChange = (e) => {
    const { name, value, type, checked } = e.target;
    setForm((prev) => ({
      ...prev,
      [name]: type === "checkbox" ? checked : value,
    }));
  };

  const handleSubmit = async (e) => {
    e.preventDefault();
    setError("");

    if (!form.name.trim() || !form.email.trim()) {
      setError("Vui lòng nhập tên và email");
      return;
    }

    if (!editingUserId && !form.password.trim()) {
      setError("Vui lòng nhập mật khẩu");
      return;
    }

    try {
      setSubmitting(true);
      const payload = {
        name: form.name.trim(),
        email: form.email.trim(),
        phone: form.phone.trim(),
        password: form.password,
        role: form.role,
        emailVerified: form.emailVerified,
      };

      if (editingUserId) {
        await api.put(`/users/${editingUserId}`, payload);
      } else {
        await api.post("/users", payload);
      }

      resetForm();
      fetchUsers();
    } catch (err) {
      console.error(err);
      setError(err.response?.data?.message || "Lưu tài khoản thất bại");
    } finally {
      setSubmitting(false);
    }
  };

  const handleEdit = (user) => {
    setShowForm(true);
    setEditingUserId(user.id);
    setForm({
      name: user.name || "",
      email: user.email || "",
      phone: user.phone || "",
      password: "",
      role: user.role || "USER",
      emailVerified: !!user.emailVerified,
    });
    setError("");
  };

  const handleDeleteUser = async (userId) => {
    if (!window.confirm("Bạn có chắc muốn xóa user này?")) return;

    try {
      await api.delete(`/users/${userId}`);
      fetchUsers();
    } catch (err) {
      console.error(err);
      alert(err.response?.data?.message || "Xóa user thất bại");
    }
  };

  const handleChangeRole = async (userId, role) => {
    try {
      await api.patch(`/users/${userId}/role`, { role });
      fetchUsers();
    } catch (err) {
      console.error(err);
      alert(err.response?.data?.message || "Cập nhật role thất bại");
    }
  };

  const handleAvatarUpload = async (userId, file) => {
    if (!file) return;

    try {
      const formData = new FormData();
      formData.append("avatar", file);
      await api.post(`/users/${userId}/avatar`, formData, {
        headers: { "Content-Type": "multipart/form-data" },
      });
      fetchUsers();
    } catch (err) {
      console.error(err);
      alert(err.response?.data?.message || "Cập nhật avatar thất bại");
    }
  };

  const handleDeleteAvatar = async (userId) => {
    if (!window.confirm("Xóa avatar của user này?")) return;

    try {
      await api.delete(`/users/${userId}/avatar`);
      fetchUsers();
    } catch (err) {
      console.error(err);
      alert(err.response?.data?.message || "Xóa avatar thất bại");
    }
  };

  return (
    <div className="page-wrap">
      <div className="section-header">
        <h2>Quản lý user</h2>
        <button
          className="primary-btn"
          onClick={() => {
            if (showForm) {
              resetForm();
            } else {
              setShowForm(true);
              setEditingUserId(null);
              setForm(defaultForm);
            }
          }}
        >
          {showForm ? "Đóng form" : "Thêm tài khoản"}
        </button>
      </div>

      {showForm && (
        <div className="court-form-card">
          <h3>{editingUserId ? "Sửa tài khoản" : "Thêm tài khoản mới"}</h3>

          <form onSubmit={handleSubmit} className="court-form">
            <div className="form-grid">
              <div className="form-group">
                <label>Họ tên</label>
                <input name="name" placeholder="Nhập họ tên" value={form.name} onChange={handleChange} />
              </div>

              <div className="form-group">
                <label>Email</label>
                <input name="email" type="email" placeholder="Nhập email" value={form.email} onChange={handleChange} />
              </div>

              <div className="form-group">
                <label>Số điện thoại</label>
                <input name="phone" placeholder="Nhập số điện thoại" value={form.phone} onChange={handleChange} />
              </div>

              <div className="form-group">
                <label>Vai trò</label>
                <select name="role" value={form.role} onChange={handleChange}>
                  <option value="USER">USER</option>
                  <option value="STAFF">STAFF</option>
                  <option value="COACH">COACH</option>
                  <option value="ADMIN">ADMIN</option>
                </select>
              </div>

              <div className="form-group">
                <label>{editingUserId ? "Mật khẩu mới (để trống nếu không đổi)" : "Mật khẩu"}</label>
                <input
                  name="password"
                  type="password"
                  placeholder={editingUserId ? "Nhập mật khẩu mới nếu muốn đổi" : "Nhập mật khẩu"}
                  value={form.password}
                  onChange={handleChange}
                />
              </div>

              <div className="form-group">
                <label>Xác minh email</label>
                <select
                  name="emailVerified"
                  value={String(form.emailVerified)}
                  onChange={(e) =>
                    setForm((prev) => ({
                      ...prev,
                      emailVerified: e.target.value === "true",
                    }))
                  }
                >
                  <option value="true">Đã xác minh</option>
                  <option value="false">Chưa xác minh</option>
                </select>
              </div>
            </div>

            {error && <div className="error-box">{error}</div>}

            <div className="form-actions">
              <button type="submit" className="primary-btn" disabled={submitting}>
                {submitting ? "Đang lưu..." : editingUserId ? "Cập nhật tài khoản" : "Tạo tài khoản"}
              </button>
            </div>
          </form>
        </div>
      )}

      <div className="table-card">
        {loading ? (
          <p>Đang tải danh sách user...</p>
        ) : users.length === 0 ? (
          <p>Chưa có user nào</p>
        ) : (
          <table>
            <thead>
              <tr>
                <th>ID</th>
                <th>Avatar</th>
                <th>Tài khoản</th>
                <th>Điện thoại</th>
                <th>Role</th>
                <th>Avatar user</th>
                <th>Xác minh email</th>
                <th>Ngày tạo</th>
                <th>Thao tác</th>
              </tr>
            </thead>
            <tbody>
              {users.map((user) => (
                <tr key={user.id}>
                  <td>{user.id}</td>
                  <td>
                    <button
                      type="button"
                      onClick={() => setPreviewUser(user)}
                      style={{ border: "none", background: "transparent", padding: 0, cursor: "pointer" }}
                    >
                      {renderAvatar(user)}
                    </button>
                  </td>
                  <td>
                    <div style={{ display: "flex", flexDirection: "column", gap: 2 }}>
                      <strong>{user.name}</strong>
                      <span style={{ color: "#6b7280", fontSize: 13 }}>{user.email}</span>
                    </div>
                  </td>
                  <td>{user.phone || "-"}</td>
                  <td>
                    <select value={user.role} onChange={(e) => handleChangeRole(user.id, e.target.value)}>
                      <option value="USER">USER</option>
                      <option value="STAFF">STAFF</option>
                      <option value="COACH">COACH</option>
                      <option value="ADMIN">ADMIN</option>
                    </select>
                  </td>
                  <td>
                    <div style={{ display: "flex", flexDirection: "column", gap: 8 }}>
                      <label className="primary-btn" style={{ display: "inline-flex", justifyContent: "center", cursor: "pointer", padding: "8px 12px" }}>
                        Tải avatar
                        <input
                          type="file"
                          accept="image/*"
                          style={{ display: "none" }}
                          onChange={(e) => handleAvatarUpload(user.id, e.target.files?.[0])}
                        />
                      </label>
                      <button
                        type="button"
                        className="primary-btn"
                        style={{ background: "#fff", color: "#c62828", border: "1px solid #f3c5c5" }}
                        onClick={() => handleDeleteAvatar(user.id)}
                        disabled={!user.avatarUrl}
                      >
                        Xóa avatar
                      </button>
                    </div>
                  </td>
                  <td>{user.emailVerified ? "Đã xác minh" : "Chưa xác minh"}</td>
                  <td>{new Date(user.createdAt).toLocaleString("vi-VN")}</td>
                  <td>
                    <div className="court-actions">
                      <button className="secondary-btn" onClick={() => handleEdit(user)}>
                        Sửa
                      </button>
                      <button className="danger-btn" onClick={() => handleDeleteUser(user.id)}>
                        Xóa
                      </button>
                    </div>
                  </td>
                </tr>
              ))}
            </tbody>
          </table>
        )}
      </div>

      {previewUser && (
        <div
          style={{
            position: "fixed",
            inset: 0,
            background: "rgba(0,0,0,0.72)",
            display: "grid",
            placeItems: "center",
            zIndex: 9999,
          }}
          onClick={() => setPreviewUser(null)}
        >
          <div
            style={{ background: "#fff", borderRadius: 20, padding: 22, minWidth: 320, maxWidth: 420 }}
            onClick={(e) => e.stopPropagation()}
          >
            <div style={{ display: "flex", justifyContent: "space-between", alignItems: "center", marginBottom: 16 }}>
              <strong>Xem avatar user</strong>
              <button type="button" className="secondary-btn" onClick={() => setPreviewUser(null)}>
                Đóng
              </button>
            </div>
            <div style={{ display: "grid", placeItems: "center", marginBottom: 14 }}>
              {previewUser.avatarUrl ? (
                <img
                  src={previewUser.avatarUrl}
                  alt={previewUser.name}
                  style={{ width: 180, height: 180, borderRadius: "50%", objectFit: "cover" }}
                />
              ) : (
                renderAvatar(previewUser)
              )}
            </div>
            <div style={{ textAlign: "center" }}>
              <div style={{ fontWeight: 800 }}>{previewUser.name || "User"}</div>
              <div style={{ color: "#6b7280", fontSize: 14 }}>{previewUser.email || ""}</div>
            </div>
          </div>
        </div>
      )}
    </div>
  );
}
